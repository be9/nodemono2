load("@aspect_bazel_lib//lib:directory_path.bzl", "directory_path")
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_library")
load("@aspect_rules_js//npm:defs.bzl", "npm_package")
load("@aspect_rules_ts//ts:defs.bzl", "ts_config", "ts_project")
load("@npm//:defs.bzl", "npm_link_all_packages")
load("//bzl:private/ts_proto_library.bzl", ts_proto_library_rule = "ts_proto_library")

def monorepo_package(
        name,
        deps):
    """
    Defines a monorepo package.
    """
    ts_project_name = name + "_ts"

    ts_config(
        name = "tsconfig",
        src = "tsconfig.json",
        visibility = [":__subpackages__"],
        deps = ["//:tsconfig"],
    )

    npm_link_all_packages(name = "node_modules")

    ts_project(
        name = ts_project_name,
        srcs = native.glob(["src/**"]),
        # Default settings
        composite = True,
        declaration = True,
        declaration_map = True,
        resolve_json_module = True,
        source_map = True,
        transpiler = "tsc",
        tsconfig = ":tsconfig",
        deps = deps,
    )

    npm_package(
        name = name,
        srcs = [
            "package.json",
            ":" + ts_project_name,
        ],
        include_runfiles = False,
        visibility = ["//visibility:public"],
    )

###################

def ts_proto_library(name, has_services = False, **kwargs):
    """
    A macro to generate TypeScript code from .proto files.

    Args:
        name: name of resulting ts_proto_library target
        has_services: whether the proto file contains a service, and therefore *_connect.{js,d.ts} should be written.
        **kwargs: additional named arguments to the ts_proto_library rule
    """
    node_modules = "@nodemono2//packages/proto:node_modules"
    protoc_gen_ts_target = "_{}.gen_ts".format(name)
    protoc_gen_ts_entry = protoc_gen_ts_target + "__entry_point"

    # Reach into the node_modules to find the entry points
    directory_path(
        name = protoc_gen_ts_entry,
        tags = ["manual"],
        directory = node_modules + "/@protobuf-ts/plugin/dir",
        path = "bin/protoc-gen-ts",
    )
    js_binary(
        name = protoc_gen_ts_target,
        data = [node_modules + "/@protobuf-ts/plugin"],
        entry_point = protoc_gen_ts_entry,
    )

    ts_proto_library_rule(
        name = "_{}".format(name),
        protoc_gen_ts = protoc_gen_ts_target,
        # The codegen always has a runtime dependency on the protobuf runtime
        deps = kwargs.pop("deps", []) + [node_modules + "/@protobuf-ts/runtime"],
        has_services = has_services,
        **kwargs
    )
    js_library(
        name = name,
        visibility = ["//visibility:public"],
        srcs = [":_{}".format(name)],
    )
