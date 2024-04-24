"Private implementation details for ts_proto_library"

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo", "js_info")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_proto//proto:defs.bzl", "ProtoInfo", "proto_common")

# buildifier: disable=function-docstring-header
def _protoc_action(ctx, proto_info, outputs, options = []):
    """Create an action like
    bazel-out/k8-opt-exec-2B5CBBC6/bin/external/com_google_protobuf/protoc $@' '' \
      '--plugin=protoc-gen-es=bazel-out/k8-opt-exec-2B5CBBC6/bin/plugin/bufbuild/protoc-gen-es.sh' \
      '--es_opt=keep_empty_files=true' '--es_opt=target=ts' \
      '--es_out=bazel-out/k8-fastbuild/bin' \
      '--descriptor_set_in=bazel-out/k8-fastbuild/bin/external/com_google_protobuf/timestamp_proto-descriptor-set.proto.bin:bazel-out/k8-fastbuild/bin/example/thing/thing_proto-descriptor-set.proto.bin:bazel-out/k8-fastbuild/bin/example/place/place_proto-descriptor-set.proto.bin:bazel-out/k8-fastbuild/bin/example/person/person_proto-descriptor-set.proto.bin' \
      example/person/person.proto
    """
    inputs = depset(proto_info.direct_sources, transitive = [proto_info.transitive_descriptor_sets])
    proto_root = proto_info.proto_source_root
    if proto_root.startswith(ctx.bin_dir.path):
        proto_root = proto_root[len(ctx.bin_dir.path) + 1:]
    plugin_output = ctx.bin_dir.path + "/" + proto_root
    proto_root = ctx.workspace_name + "/" + proto_root

    args = ctx.actions.args()
    args.add_joined(["--plugin", "protoc-gen-ts", ctx.executable.protoc_gen_ts.path], join_with = "=")
    for opt in options:
        args.add_joined(["--ts_opt", opt], join_with = "=")
    args.add_joined(["--ts_out", plugin_output], join_with = "=")

    args.add("--descriptor_set_in")
    args.add_joined(proto_info.transitive_descriptor_sets, join_with = ":")

    args.add_all([paths.relativize(path = file.path, start = proto_info.proto_source_root) for file in proto_info.direct_sources])

    ctx.actions.run(
        executable = ctx.executable.protoc,
        progress_message = "Generating .js/.d.ts from %{label}",
        outputs = outputs,
        inputs = inputs,
        mnemonic = "ProtocGenTs",
        arguments = [args],
        tools = [ctx.executable.protoc_gen_ts],
        env = {"BAZEL_BINDIR": ctx.bin_dir.path},
    )

def _declare_outs(ctx, info, ext):
    outs = proto_common.declare_generated_files(ctx.actions, info, ext)
    if ctx.attr.has_services:
        outs.extend(proto_common.declare_generated_files(ctx.actions, info, ".client" + ext))
        outs.extend(proto_common.declare_generated_files(ctx.actions, info, ".server" + ext))
    return outs

def _ts_proto_library_impl(ctx):
    info = ctx.attr.proto[ProtoInfo]
    js_outs = _declare_outs(ctx, info, ".js")
    dts_outs = _declare_outs(ctx, info, ".d.ts")

    protoc_options = [
        "long_type_string",
        "keep_enum_prefix",
        "output_javascript",
        "output_legacy_commonjs",
    ]
    if ctx.attr.has_services:
        protoc_options.append("client_generic")
        protoc_options.append("server_generic")

    _protoc_action(ctx, info, js_outs + dts_outs, protoc_options)

    direct_srcs = depset(js_outs)
    direct_decls = depset(dts_outs)

    npm_linked_packages = js_lib_helpers.gather_npm_linked_packages(
        srcs = [],
        deps = ctx.attr.deps,
    )
    npm_package_store_deps = js_lib_helpers.gather_npm_package_store_deps(
        targets = ctx.attr.deps,
    )
    return [
        DefaultInfo(
            files = direct_srcs,
            runfiles = js_lib_helpers.gather_runfiles(
                ctx = ctx,
                sources = direct_srcs,
                data = [],
                deps = ctx.attr.deps,
            ),
        ),
        OutputGroupInfo(types = direct_decls),
        js_info(
            declarations = direct_decls,
            sources = direct_srcs,
            transitive_declarations = js_lib_helpers.gather_transitive_declarations(
                declarations = dts_outs,
                targets = ctx.attr.deps,
            ),
            transitive_sources = js_lib_helpers.gather_transitive_sources(
                sources = js_outs,
                targets = ctx.attr.deps,
            ),
            npm_linked_packages = npm_linked_packages.direct,
            npm_package_store_deps = npm_package_store_deps,
            transitive_npm_linked_package_files = npm_linked_packages.transitive_files,
            transitive_npm_linked_packages = npm_linked_packages.transitive,
        ),
    ]

ts_proto_library = rule(
    implementation = _ts_proto_library_impl,
    attrs = {
        "deps": attr.label_list(
            providers = [JsInfo],
            doc = "Other ts_proto_library rules. TODO: could we collect them with an aspect",
        ),
        "has_services": attr.bool(
            doc = "whether the source proto includes any services",
            default = True,
        ),
        "proto": attr.label(
            doc = "proto_library to generate TS for",
            providers = [ProtoInfo],
            mandatory = True,
        ),
        "protoc": attr.label(default = "@com_google_protobuf//:protoc", executable = True, cfg = "exec"),
        "protoc_gen_ts": attr.label(
            doc = "protoc plugin to generate TS",
            mandatory = True,
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = COPY_FILE_TO_BIN_TOOLCHAINS,
)
