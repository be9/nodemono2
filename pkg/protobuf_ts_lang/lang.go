package protobuf_ts_lang

import (
	"fmt"
	"log"
	"path/filepath"
	"strings"

	"github.com/bazelbuild/bazel-gazelle/label"
	"github.com/bazelbuild/bazel-gazelle/language"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

const (
	langName           = "protobuf_ts"
	protoLibraryRule   = "proto_library"
	tsProtoLibraryRule = "ts_proto_library"
)

type protobufTsLang struct {
	language.BaseLang
}

func (*protobufTsLang) Name() string { return langName }

func NewLanguage() language.Language {
	return &protobufTsLang{}
}

var kinds = map[string]rule.KindInfo{
	tsProtoLibraryRule: {
		MatchAttrs:    []string{"srcs"},
		NonEmptyAttrs: map[string]bool{"srcs": true},
		MergeableAttrs: map[string]bool{
			"srcs": true,
			"rpc":  true,
		},
		ResolveAttrs: map[string]bool{"deps": true},
	},
}

func (*protobufTsLang) Kinds() map[string]rule.KindInfo { return kinds }

func (*protobufTsLang) ApparentLoads(func(string) string) []rule.LoadInfo {
	return []rule.LoadInfo{
		{
			Name: fmt.Sprintf("@nodemono2//bzl:defs.bzl"),
			Symbols: []string{
				"ts_proto_library",
			},
		},
	}
}

func (*protobufTsLang) GenerateRules(args language.GenerateArgs) (result language.GenerateResult) {
	protoLibraries, emptyLibraries := getProtoLibraries(args)

	// Generate one ts_proto_library() per proto_library()
	for _, protoLibrary := range protoLibraries {
		ruleName := protoLibrary.Name() + "_ts"
		addTsProtoRule(args, protoLibrary, ruleName, &result)
	}

	// Remove any ts_proto_library() targets associated with now-empty proto_library() targets
	for _, emptyLibrary := range emptyLibraries {
		ruleName := emptyLibrary.Name() + "_ts"
		emptyRule := rule.NewRule("ts_proto_library", ruleName)
		result.Empty = append(result.Empty, emptyRule)
	}
	return
}

func getProtoLibraries(args language.GenerateArgs) ([]*rule.Rule, []*rule.Rule) {
	protos := make([]*rule.Rule, 0, len(args.OtherGen))
	emptyProtos := make([]*rule.Rule, 0)

	for _, r := range args.OtherGen {
		if r.Kind() == protoLibraryRule {
			protos = append(protos, r)
		}
	}

	for _, r := range args.OtherEmpty {
		if r.Kind() == protoLibraryRule {
			emptyProtos = append(emptyProtos, r)
		}
	}

	return protos, emptyProtos
}

func addTsProtoRule(args language.GenerateArgs, protoLibrary *rule.Rule, ruleName string, result *language.GenerateResult) {
	protoRuleLabel := label.New("", args.Rel, protoLibrary.Name())
	protoRuleLabelStr := protoRuleLabel.Rel("", args.Rel)

	r := rule.NewRule(tsProtoLibraryRule, ruleName)
	r.SetAttr("proto", protoRuleLabelStr.String())

	// this should work in `gazelle:proto file` mode where proto source is 1:1 mapped to proto_library name
	protoPath := filepath.Join(args.Dir, strings.ReplaceAll(protoLibrary.Name(), "_proto", ".proto"))
	protoInfo, err := analyzeProtoFile(protoPath)
	if err != nil {
		log.Printf("cannot parse proto: %v", err)
	}

	if !protoInfo.hasMessages && !protoInfo.hasEnums && !protoInfo.hasServices {
		return
	}

	if protoInfo.hasServices {
		r.SetAttr("has_services", true)
	}

	result.Gen = append(result.Gen, r)
	result.Imports = append(result.Imports, nil)
}
