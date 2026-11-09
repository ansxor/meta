def render_type:
  if .kind == "typeRef" then
    .typeRef.typeName + (if .typeRef.typeParams then "<" + ([.typeRef.typeParams[] | render_type] | join(", ")) + ">" else "" end)
  elif .kind == "keyword" then .keyword
  elif .kind == "union" then ([.union[] | render_type] | join(" | "))
  elif .kind == "intersection" then ([.intersection[] | render_type] | join(" & "))
  elif .kind == "array" then (.array | render_type) + "[]"
  elif .kind == "parenthesized" then "(" + (.parenthesized | render_type) + ")"
  elif .kind == "fnOrConstructor" then
    "(" + ([.fnOrConstructor.params[] | .name + ": " + (.tsType | render_type)] | join(", ")) + ") => " + (.fnOrConstructor.tsType | render_type)
  elif .kind == "tuple" then "[" + ([.tuple[] | render_type] | join(", ")) + "]"
  elif .kind == "indexed_access" then
    (.indexedAccess.objType | render_type) + "[" + (.indexedAccess.indexType | render_type) + "]"
  elif .kind == "mapped" then
    "{ [" + .mappedType.typeParam.name + " in " + (.mappedType.typeParam.constraint | render_type) + "]: " + (.mappedType.tsType | render_type) + " }"
  elif .kind == "typeLiteral" then
    "{ " + ([.typeLiteral.properties[] | .name + (if .optional then "?" else "" end) + ": " + (.tsType | render_type)] | join("; ")) + " }"
  elif .kind == "conditional" then
    (.conditionalType.checkType | render_type) + " extends " + (.conditionalType.extendsType | render_type) +
    " ? " + (.conditionalType.trueType | render_type) + " : " + (.conditionalType.falseType | render_type)
  elif .kind == "literal" then
    if .literal.kind == "string" then "\"" + .literal.string + "\""
    elif .literal.kind == "number" then (.literal.number | tostring)
    elif .literal.kind == "boolean" then (.literal.boolean | tostring)
    else .repr // .kind
    end
  elif .kind == "rest" then "..." + (.rest | render_type)
  elif .kind == "optional" then (.optional | render_type) + "?"
  elif .kind == "typeOperator" then .typeOperator.operator + " " + (.typeOperator.tsType | render_type)
  elif .kind == "typePredicate" then
    (if .typePredicate.asserts then "asserts " else "" end) + .typePredicate.param.name +
    (if .typePredicate.type then " is " + (.typePredicate.type | render_type) else "" end)
  elif .kind == "importType" then .repr // "import(...)"
  elif .kind == "infer" then "infer " + .infer.typeParam.name
  elif .repr and .repr != "" then .repr
  else .kind
  end;

def render_node:
  if .kind == "function" then
    "function " + .name +
    (if (.functionDef.typeParams | length) > 0 then
      "<" + ([.functionDef.typeParams[] |
        .name +
        (if .constraint then " extends " + (.constraint | render_type) else "" end) +
        (if .default then " = " + (.default | render_type) else "" end)
      ] | join(", ")) + ">"
    else "" end) +
    "(" + ([.functionDef.params[] |
      (if .kind == "rest" then "..." else "" end) +
      .name + (if .optional then "?" else "" end) +
      (if .tsType then ": " + (.tsType | render_type) else "" end)
    ] | join(", ")) + ")" +
    (if .functionDef.returnType then ": " + (.functionDef.returnType | render_type) else "" end)

  elif .kind == "interface" then
    "interface " + .name +
    (if (.interfaceDef.typeParams | length) > 0 then
      "<" + ([.interfaceDef.typeParams[] | .name] | join(", ")) + ">"
    else "" end) +
    (if (.interfaceDef.extends | length) > 0 then
      " extends " + ([.interfaceDef.extends[] | .repr] | join(", "))
    else "" end) +
    " {\n" +
    ([.interfaceDef.properties[] |
      "  " + .name + (if .optional then "?" else "" end) +
      (if .tsType then ": " + (.tsType | render_type) else "" end)
    ] | join("\n")) +
    (if (.interfaceDef.methods | length) > 0 then
      "\n" + ([.interfaceDef.methods[] |
        "  " + .name +
        "(" + ([.params[] |
          .name + (if .optional then "?" else "" end) +
          (if .tsType then ": " + (.tsType | render_type) else "" end)
        ] | join(", ")) + ")" +
        (if .returnType then ": " + (.returnType | render_type) else "" end)
      ] | join("\n"))
    else "" end) +
    (if (.interfaceDef.callSignatures | length) > 0 then
      "\n" + ([.interfaceDef.callSignatures[] |
        "  (" + ([.params[] |
          .name + (if .optional then "?" else "" end) +
          (if .tsType then ": " + (.tsType | render_type) else "" end)
        ] | join(", ")) + ")" +
        (if .tsType then ": " + (.tsType | render_type) else "" end)
      ] | join("\n"))
    else "" end) +
    (if (.interfaceDef.indexSignatures | length) > 0 then
      "\n" + ([.interfaceDef.indexSignatures[] |
        "  [" + ([.params[] |
          .name + ": " + (.tsType | render_type)
        ] | join(", ")) + "]: " + (.tsType | render_type)
      ] | join("\n"))
    else "" end) +
    "\n}"

  elif .kind == "typeAlias" then
    "type " + .name +
    (if (.typeAliasDef.typeParams | length) > 0 then
      "<" + ([.typeAliasDef.typeParams[] |
        .name +
        (if .constraint then " extends " + (.constraint | render_type) else "" end) +
        (if .default then " = " + (.default | render_type) else "" end)
      ] | join(", ")) + ">"
    else "" end) +
    " = " + (.typeAliasDef.tsType | render_type)

  elif .kind == "variable" then
    "const " + .name +
    (if .variableDef.tsType then ": " + (.variableDef.tsType | render_type) else "" end)

  elif .kind == "class" then
    "class " + .name +
    (if (.classDef.typeParams | length) > 0 then
      "<" + ([.classDef.typeParams[] | .name] | join(", ")) + ">"
    else "" end) +
    (if .classDef.superClass then " extends " + .classDef.superClass else "" end) +
    (if (.classDef.implements | length) > 0 then
      " implements " + ([.classDef.implements[] | .repr] | join(", "))
    else "" end) +
    " {\n" +
    ([.classDef.properties[] |
      "  " + (if .isStatic then "static " else "" end) +
      (if .accessibility then .accessibility + " " else "" end) +
      (if .readonly then "readonly " else "" end) +
      .name + (if .optional then "?" else "" end) +
      (if .tsType then ": " + (.tsType | render_type) else "" end)
    ] | join("\n")) +
    (if (.classDef.methods | length) > 0 then
      "\n" + ([.classDef.methods[] |
        "  " + (if .isStatic then "static " else "" end) +
        .name +
        "(" + ([.functionDef.params[] |
          .name + (if .optional then "?" else "" end) +
          (if .tsType then ": " + (.tsType | render_type) else "" end)
        ] | join(", ")) + ")" +
        (if .functionDef.returnType then ": " + (.functionDef.returnType | render_type) else "" end)
      ] | join("\n"))
    else "" end) +
    "\n}"

  elif .kind == "enum" then
    "enum " + .name + " {\n" +
    ([.enumDef.members[] | "  " + .name + (if .init then " = " + (.init | render_type) else "" end)] | join(",\n")) +
    "\n}"

  elif .kind == "namespace" then
    "namespace " + .name

  else .kind + " " + .name
  end +
  (if .jsDoc.doc then "\n\n" + .jsDoc.doc else "" end);

# Find matching node in top-level or inside namespaces
def find_nodes(kind; name):
  .nodes[] | select(.kind != "import") |
  if .kind == "namespace" then
    .namespaceDef.elements[] | select(.kind == kind and .name == name)
  else
    select(.kind == kind and .name == name)
  end;

find_nodes($kind; $name) | render_node
