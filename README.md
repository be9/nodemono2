# nodemono2

This repository contains a mock Node monorepo that resembles one real closed-source TypeScript/Node monorepo. It was
created to support easier experimentation with the tooling. Packages' third-party dependencies resemble dependencies 
in the real monorepo.

The ultimate goal is effective Docker image building for TypeScript/Node services, using caches to maximize performance.

## Monorepo structure

The monorepo is package-based (`/packages/*`) and uses [pnpm](https://pnpm.io/) to handle dependencies and workspaces.

### packages/lib1 (@nodemono2/lib1)

A backend package that depends on [Puppeteer](https://www.npmjs.com/package/puppeteer). Its only exported
function, `getPuppeteerVersion()`, starts the browser, retrieves and returns its version. 

### packages/lib2 (@nodemono2/lib2)

Another backend package that depends on a multitude of Node packages with binary extensions:

* [aws-crt](https://www.npmjs.com/package/aws-crt)
* [cpu-features](https://www.npmjs.com/package/cpu-features)
* [node-sass](https://www.npmjs.com/package/node-sass)
* [sqlite3](https://www.npmjs.com/package/sqlite3)
* [ssh2](https://www.npmjs.com/package/ssh2)

The only exported function, `getSomeInfo()`, makes a bunch of calls to the packages listed above (mostly getting
versions), and returns collected information as a JS object. 

### proto/src 

A directory tree with 1370 .proto files borrowed from [googleapis](https://github.com/googleapis/googleapis).
The files refer to each other by relative paths: `import "grafeas/v1/common.proto"` refers to
`/proto/src/grafeas/v1/common.proto`.

### packages/proto (@nodemono2/proto)

This package carries a centralized collection of all the protos from `proto/src` compiled to TypeScript using
[protobuf-ts](https://github.com/timostamm/protobuf-ts).

For any proto source:
```protobuf
// proto/src/foo/bar.proto
syntax = "proto3";

package foo;

message TestMessage {
  string test = 1;
}
```
it will be possible to
```typescript
import { TestMessage } from '@nodemono2/proto/build/foo/bar';

const msg = TestMessage.create({ test: 'hello' });
```
In case services are defined in a proto:
```protobuf
// proto/src/foo/baz.proto
syntax = "proto3";

package foo;

message TestMethodRequest {} 
message TestMethodResponse {}

service TestService {
  rpc TestMethod(TestMethodRequest) returns (TestMethodResponse);
}
```
there will be two more files generated:
```typescript
import { ITestServiceClient } from '@nodemono2/proto/build/foo/baz.client';
import { ITestService } from '@nodemono2/proto/build/foo/baz.server';

// ...
```

### packages/app1

A backend "app" with JSON HTTP API. 

Monorepo dependencies:
* `@nodemono2/lib1`
* `@nodemono2/lib2` 
* `@nodemono2/proto`

The API handler invokes methods from these packages and returns a JSON result with aggregated data. Invoking the
handler is thus an integration test that verifies that all dependencies were correctly installed (including binary
extensions) and work in runtime.

### packages/next-app

This is a [Next.js](https://nextjs.org/) app that aims to load packages with binary extensions in the backend
and proto in the frontend, being another integration test.

## Regular Node tooling with Turborepo

One tooling variant is based on [Turborepo](https://turbo.build/repo):

* Every package defines the `build:self` script that builds the package assuming that its dependencies are already
  built.
* `packages/proto` also defines the `codegen` script that generates `*.ts` from `proto/src/**.proto`. This is done by
  running `buf generate`.
* Dockerfiles (see `packages/app1/Dockerfile` and `packages/next-app/Dockerfile`) use 
  [`turbo prune`](https://turbo.build/repo/docs/reference/command-line-reference/prune) to 
  dynamically generate a subset of the monorepo (`packages/*` and `pnpm-lock.yaml`); then  
  `turbo run codegen` and `turbo run build:self` are invoked to generate/compile all relevant TypeScript sources
  in correct order (toposort). 
* This is not implemented in the repo yet, but both `turbo run` invocations will benefit from using a 
  [remote cache](https://turbo.build/repo/docs/core-concepts/remote-caching).  

## Bazel-based tooling

Bazel is currently explored as a potential replacement for Turborepo.

### Work done so far

It was fairly easy to bazelify `packages/lib1` and `packages/lib2` using Aspect's [rules_ts](https://github.com/aspect-build/rules_ts). 
`bazel build //packages/lib1 //packages/lib2` works; `bazel-bin/packages/lib{1,2}` contain correct `.js` and `.d.ts` files.
A macro was created to invoke all the needed rules, see `monorepo_package` in `/bzl/defs.bzl`. 

Properly handling `packages/proto` appeared to be much harder:

* The `buf generate`-like approach where everything is generated not knowing exactly how many files will be out is
  not native to Bazel, so we need build files with `proto_library` and another rule that generates `*.ts` files from
  the `proto_library`.
* Gazelle can generate `proto_library`; however in default mode, it generates a single `proto_library` rule per directory.
  Given the fact that every `*.proto` source maps to either 1 or 3 `*.ts` files, we need per-file granularity, therefore
  `gazelle:proto file` mode had to be used.
* To handle `*.ts` generation, the `ts_proto_library` rule (see `/bzl/defs.bzl`) was created by hacking the [rule with the same name](https://github.com/aspect-build/rules_ts/blob/main/ts/proto.bzl) 
  from `rules_ts`. By coincidence, `rules_ts` use [`protobuf-es`](https://github.com/bufbuild/protobuf-es) created by the same
  `protobuf-ts` author (timostamm); the difference is that `protobuf-ts` generates `*.ts` that yet needs to be compiled, where
  `protobuf-ts` directly generates `*.js` and `*.d.ts`. One other difference: `protobuf-ts` contains a single plugin, while `es` and
  `es-connect` are separate.
* To generate `ts_proto_library` invocations, a Gazelle plugin was created (see `pkg/protobuf_ts_lang`). 

### Problems 

...

### Work to do

* Add rules to compile generated proto `*.ts` to `*.js` and `*.d.ts`.
* Bazelify `packages/app1`.
* Figure out Docker image for `app1`.
* Bazelify `packages/next-app`.
* Figure out Docker image for `next-app`.
