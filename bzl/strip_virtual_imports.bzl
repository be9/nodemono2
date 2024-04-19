load("@aspect_bazel_lib//lib:copy_file.bzl", "COPY_FILE_TOOLCHAINS", "copy_file_action")
load("@aspect_rules_js//js:providers.bzl", "JsInfo", "js_info")

def _strip_virtual_imports_impl(ctx):
    depsets = [
        src[JsInfo].sources
        for src in ctx.attr.srcs
    ]
    depsets.extend([
        src[JsInfo].declarations
        for src in ctx.attr.srcs
    ])

    all = depset([], transitive = depsets)
    outputs = []

    for f in all.to_list():
        dst = ctx.actions.declare_file(ctx.label.name + "/" + _unclutter_path(f))
        outputs.append(dst)

        copy_file_action(
            ctx = ctx,
            src = f,
            dst = dst,
        )

    files = depset(direct = outputs)
    runfiles = ctx.runfiles(files = outputs)
    return [DefaultInfo(files = files, runfiles = runfiles)]

def _unclutter_path(file):
    # proto/src/grafeas/v1/_virtual_imports/slsa_provenance_proto/grafeas/v1/slsa_provenance.js
    #  ->
    # grafeas/v1/slsa_provenance.js
    parts = file.path.split("/")
    vi = parts.index("_virtual_imports")
    return "/".join(parts[vi + 2:])

strip_virtual_imports = rule(
    implementation = _strip_virtual_imports_impl,
    provides = [DefaultInfo],
    attrs = {
        "srcs": attr.label_list(
            providers = [JsInfo],
            doc = "Other ts_proto_library rules. TODO: could we collect them with an aspect",
        ),
    },
    toolchains = COPY_FILE_TOOLCHAINS,
)
