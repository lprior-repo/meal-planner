#!/usr/bin/env nu
# CUE Schema Query Engine
# Queries CUE files and outputs contract information
#
# Usage:
#   nu scripts/docs/cue_query.nu                          # Show all contracts
#   nu scripts/docs/cue_query.nu --binary foods_search    # Specific binary
#   nu scripts/docs/cue_query.nu --domain fatsecret       # Domain overview
#   nu scripts/docs/cue_query.nu --json                   # JSON output

let schema_dir = "schemas/cue"
let fatsecret_schema = $"{$schema_dir}/fatsecret_foods_complete.cue"
let base_schema = $"{$schema_dir}/base.cue"

# Parse command line arguments
let args = ($env | get ARGS | default [] | split row " ")
let binary_name = ($args | where $it == "--binary" | length) > 0
let domain_name = ($args | where $it == "--domain" | length) > 0
let json_output = ($args | where $it == "--json" | length) > 0

# Get all input/output type names from CUE
def "parse cue types" [] {
    cue definitions $fatsecret_schema --json 
        | from json 
        | objects 
        | where key =~ "^#.*(Input|Output)$" 
        | get key
}

# Get type definition from CUE
def "get type" [type_name: string] {
    cue def $fatsecret_schema --json 
        | from json 
        | get $type_name
}

# Format type as Nushell record
def "format type" [type_name: string] -> record {
    let def = (get type $type_name)
    {
        name: $type_name
        type: "input"
        properties: ($def | if ($def | describe) == "record" { $def } else { {} })
        required: (($def | objects | where value == "" | get key) // TODO: detect required fields)
    }
}

# Print human-readable report
def "print report" [] {
    let input_types = (parse cue types | where $it =~ "Input$")
    let output_types = (parse cue types | where $it =~ "Output$")

    print $"FATSECRET FOODS DOMAIN CONTRACTS"
    print "================================"
    print $""
    print $"Input Types: ($input_types | length)"
    print $"Output Types: ($output_types | length)"
    print $""
    
    for $input in $input_types {
        let binary = ($input | str replace "Input$" "" | str replace "_" "-")
        print $"($binary)"
        print $"  Input: ($input)"
        let output = ($input | str replace "Input" "Output")
        print $"  Output: ($output)"
        print $""
    }
}

# Print JSON report
def "print json" [] {
    let input_types = (parse cue types | where $it =~ "Input$")
    
    $input_types | each {|input|
        let output = ($input | str replace "Input" "Output")
        {
            binary: ($input | str replace "Input$" "" | str replace "_" "-")
            input_type: $input
            output_type: $output
        }
    } | to json
}

# Main
if $json_output {
    print json
} else {
    print report
}
