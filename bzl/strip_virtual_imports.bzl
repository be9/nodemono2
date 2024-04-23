load("@aspect_bazel_lib//lib:copy_file.bzl", "COPY_FILE_TOOLCHAINS", "copy_file_action")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo", "js_info")

def _strip_virtual_imports_impl(ctx):
    #        transitive_declarations = transitive_declarations,
    #        npm_linked_package_files = npm_linked_package_files,
    #        npm_linked_packages = npm_linked_packages,
    #        npm_package_store_deps = npm_package_store_deps,
    #        transitive_npm_linked_package_files = transitive_npm_linked_package_files,
    #        transitive_npm_linked_packages = transitive_npm_linked_packages,
    #
    src_depsets = [
        src[JsInfo].sources
        for src in ctx.attr.srcs
    ]
    decl_depsets = [
        src[JsInfo].declarations
        for src in ctx.attr.srcs
    ]

    def _declare_output(ctx, file):
        dst = ctx.actions.declare_file(ctx.label.name + "/" + _unclutter_path(file))
        copy_file_action(
            ctx = ctx,
            src = file,
            dst = dst,
        )
        return dst

    src_outputs = [
        _declare_output(ctx, f)
        for f in depset([], transitive = src_depsets).to_list()
    ]
    decl_outputs = [
        _declare_output(ctx, f)
        for f in depset([], transitive = decl_depsets).to_list()
    ]
    all_outputs = src_outputs + decl_outputs

    npm_linked_packages = js_lib_helpers.gather_npm_linked_packages(
        srcs = ctx.attr.srcs,
        deps = [],
    )
    npm_package_store_deps = js_lib_helpers.gather_npm_package_store_deps(
        targets = ctx.attr.srcs,
    )

    return [
        DefaultInfo(files = depset(all_outputs), runfiles = ctx.runfiles(files = all_outputs)),
        js_info(
            sources = depset(src_outputs),
            declarations = depset(decl_outputs),
            transitive_declarations = js_lib_helpers.gather_transitive_declarations(
                declarations = [],
                targets = ctx.attr.srcs,
            ),
            transitive_sources = js_lib_helpers.gather_transitive_sources(
                sources = [],
                targets = ctx.attr.srcs,
            ),
            npm_linked_packages = npm_linked_packages.direct,
            npm_package_store_deps = npm_package_store_deps,
            transitive_npm_linked_package_files = npm_linked_packages.transitive_files,
            transitive_npm_linked_packages = npm_linked_packages.transitive,
        ),
    ]

def _unclutter_path(file):
    # proto/src/grafeas/v1/_virtual_imports/slsa_provenance_proto/grafeas/v1/slsa_provenance.js
    #  ->
    # grafeas/v1/slsa_provenance.js
    parts = file.path.split("/")
    vi = parts.index("_virtual_imports")
    return "/".join(parts[vi + 2:])

strip_virtual_imports = rule(
    implementation = _strip_virtual_imports_impl,
    attrs = {
        "srcs": attr.label_list(
            providers = [JsInfo],
            doc = "Other ts_proto_library rules. TODO: could we collect them with an aspect",
        ),
    },
    toolchains = COPY_FILE_TOOLCHAINS,
)
