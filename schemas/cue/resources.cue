// Windmill Resource Type Contracts
// Defines the schema for Windmill resources used by scripts and flows

package mealplanner

// =============================================================================
// RESOURCE TYPE DEFINITIONS
// These match the Windmill resource-type.yaml files
// =============================================================================

// FatSecret API Resource Type
// File: windmill/fatsecret.resource-type.yaml
#FatSecretResourceType: {
	description: "FatSecret Platform API OAuth 1.0a credentials"
	format_extension: null
	schema: {
		type: "object"
		properties: {
			consumer_key: {
				type:        "string"
				description: "FatSecret API consumer key"
			}
			consumer_secret: {
				type:        "string"
				description: "FatSecret API consumer secret"
			}
		}
		required: ["consumer_key", "consumer_secret"]
	}
}

// Tandoor API Resource Type
// File: windmill/tandoor.resource-type.yaml
#TandoorResourceType: {
	description: "Tandoor Recipes API connection"
	format_extension: null
	schema: {
		type: "object"
		properties: {
			base_url: {
				type:        "string"
				description: "Base URL of Tandoor instance"
			}
			api_token: {
				type:        "string"
				description: "Tandoor API token"
			}
		}
		required: ["base_url", "api_token"]
	}
}

// =============================================================================
// RESOURCE INSTANCES
// These match the actual resource.yaml files
// =============================================================================

// FatSecret API Resource Instance
// File: windmill/u/admin/fatsecret_api.resource.yaml
#FatSecretResourceInstance: {
	path:         "u/admin/fatsecret_api"
	resource_type: "fatsecret"
	value: #FatSecretResource
}

// Tandoor API Resource Instance
// File: windmill/u/admin/tandoor_api.resource.yaml
#TandoorResourceInstance: {
	path:         "u/admin/tandoor_api"
	resource_type: "tandoor"
	value: #TandoorResource
}

// =============================================================================
// RESOURCE REFERENCES
// How resources are referenced in flows
// =============================================================================

// Standard resource reference patterns
#FatSecretResourceRef: "$res:u/admin/fatsecret_api"
#TandoorResourceRef:   "$res:u/admin/tandoor_api"

// Generic resource reference pattern
#ResourceRef: =~"^\\$res:[a-z]/.+$"
