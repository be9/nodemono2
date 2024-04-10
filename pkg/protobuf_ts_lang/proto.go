package protobuf_ts_lang

import (
	"errors"

	"github.com/jhump/protoreflect/desc/protoparse"
	"github.com/jhump/protoreflect/desc/protoparse/ast"
)

// doesHaveRpc returns true if there's at least 1 rpc service declared in the proto file.
func doesHaveRpc(protoFilePath string) (bool, error) {
	parser := &protoparse.Parser{}
	parsed, err := parser.ParseToAST(protoFilePath)
	if err != nil {
		return false, err
	}

	if len(parsed) != 1 {
		return false, errors.New("expected exactly one ast")
	}

	for _, decl := range parsed[0].Decls {
		if _, ok := decl.(*ast.ServiceNode); ok {
			return true, nil
		}
	}

	return false, nil
}
