package protobuf_ts_lang

import (
	"errors"

	"github.com/jhump/protoreflect/desc/protoparse"
	"github.com/jhump/protoreflect/desc/protoparse/ast"
)

type protoFileAnalysisResult struct {
	hasMessages bool
	hasEnums    bool
	hasServices bool
}

func analyzeProtoFile(protoFilePath string) (result protoFileAnalysisResult, err error) {
	parser := &protoparse.Parser{}
	var parsed []*ast.FileNode
	parsed, err = parser.ParseToAST(protoFilePath)
	if err != nil {
		return
	}

	if len(parsed) != 1 {
		err = errors.New("expected exactly one ast")
		return
	}

	for _, decl := range parsed[0].Decls {
		switch decl.(type) {
		case *ast.ServiceNode:
			result.hasServices = true
		case *ast.EnumNode:
			result.hasEnums = true
		case *ast.MessageNode:
			result.hasMessages = true
		}
	}

	return
}
