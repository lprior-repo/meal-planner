// Windmill Flow Contracts
// Flows: oauth_setup, import_recipe, batch_import_recipes

package mealplanner

// =============================================================================
// f/fatsecret/oauth_setup
// Complete OAuth flow: get auth URL → user authorizes → exchange for token
// =============================================================================

#OAuthSetupFlowInput: {
	// No input required - uses static resources
}

#OAuthSetupFlowOutput: {
	// Step a: oauth_start
	a: #OAuthStartOutput

	// Step b: suspend for user authorization (returns resume URLs)
	b: {
		resume:      string  // resume URL
		cancel:      string  // cancel URL
		description: _       // markdown render instructions
	}

	// Step c: oauth_complete
	c: #OAuthCompleteOutput

	// Step d: get_profile (verification)
	d: #GetProfileOutput
}

#OAuthSetupFlow: {
	summary:     "FatSecret OAuth Setup"
	description: "Connect your FatSecret account"
	value: {
		modules: [
			// Step a: Get authorization URL
			{
				id:      "a"
				summary: "Get authorization URL"
				value: {
					type: "script"
					path: "f/fatsecret/oauth_start"
					input_transforms: {
						fatsecret: {
							type:  "static"
							value: "$res:u/admin/fatsecret_api"
						}
						callback_url: {
							type:  "static"
							value: "oob"
						}
					}
				}
			},
			// Step b: Suspend for user input
			{
				id:      "b"
				summary: "Authorize and enter verifier"
				suspend: {
					required_events: 1
					timeout:         900  // 15 minutes
					resume_form: {
						schema: {
							type:  "object"
							order: ["verifier"]
							properties: {
								verifier: {
									type:        "string"
									title:       "Verifier Code"
									description: "After authorizing, paste the code FatSecret displays"
								}
							}
							required: ["verifier"]
						}
					}
				}
				value: {
					type:     "rawscript"
					language: "bun"
					content:  string  // TypeScript to get resume URLs
					input_transforms: {
						auth_url: {
							type: "javascript"
							expr: "results.a.auth_url"
						}
					}
				}
			},
			// Step c: Exchange for access token
			{
				id:      "c"
				summary: "Complete OAuth"
				value: {
					type: "script"
					path: "f/fatsecret/oauth_complete"
					input_transforms: {
						fatsecret: {
							type:  "static"
							value: "$res:u/admin/fatsecret_api"
						}
						oauth_token: {
							type: "javascript"
							expr: "results.a.oauth_token"
						}
						oauth_token_secret: {
							type: "javascript"
							expr: "results.a.oauth_token_secret"
						}
						oauth_verifier: {
							type: "javascript"
							expr: "resume.verifier"
						}
					}
				}
			},
			// Step d: Verify connection
			{
				id:      "d"
				summary: "Verify connection"
				value: {
					type: "script"
					path: "f/fatsecret/get_profile"
					input_transforms: {
						fatsecret: {
							type:  "static"
							value: "$res:u/admin/fatsecret_api"
						}
						oauth_token: {
							type: "javascript"
							expr: "results.c.oauth_token"
						}
						oauth_token_secret: {
							type: "javascript"
							expr: "results.c.oauth_token_secret"
						}
					}
				}
			},
		]
		same_worker: false
	}
	schema: {
		"$schema":   "https://json-schema.org/draft/2020-12/schema"
		type:        "object"
		properties: {}
		required: []
	}
}

// =============================================================================
// f/tandoor/import_recipe
// Scrape recipe from URL, derive source tag, create in Tandoor
// =============================================================================

#ImportRecipeFlowInput: {
	url:                  string & =~"^https?://"  // recipe URL to import
	additional_keywords?: [...string]              // extra tags, default []
}

#ImportRecipeFlowOutput: {
	// Step scrape
	scrape: #TandoorScrapeRecipeOutput

	// Step derive_source_tag
	derive_source_tag: string  // e.g., "serious-eats"

	// Step create
	create: #TandoorCreateRecipeOutput
}

#ImportRecipeFlow: {
	summary:     "Import recipe from URL"
	description: string
	value: {
		modules: [
			// Step: Scrape recipe
			{
				id: "scrape"
				value: {
					type: "script"
					path: "f/tandoor/scrape_recipe"
					input_transforms: {
						tandoor: {
							type:  "static"
							value: "$res:u/admin/tandoor_api"
						}
						url: {
							type: "javascript"
							expr: "flow_input.url"
						}
					}
				}
			},
			// Step: Derive source tag from domain
			{
				id: "derive_source_tag"
				value: {
					type:     "rawscript"
					language: "python3"
					content:  string  // Python URL parsing
					input_transforms: {
						url: {
							type: "javascript"
							expr: "flow_input.url"
						}
					}
				}
			},
			// Step: Create recipe
			{
				id: "create"
				value: {
					type: "script"
					path: "f/tandoor/create_recipe"
					input_transforms: {
						tandoor: {
							type:  "static"
							value: "$res:u/admin/tandoor_api"
						}
						recipe: {
							type: "javascript"
							expr: "results.scrape.recipe_json"
						}
						additional_keywords: {
							type: "javascript"
							expr: "[results.derive_source_tag].concat(flow_input.additional_keywords || [])"
						}
					}
				}
			},
		]
	}
	schema: {
		"$schema": "https://json-schema.org/draft/2020-12/schema"
		type:      "object"
		properties: {
			url: {
				type:        "string"
				description: "Recipe URL to import"
			}
			additional_keywords: {
				type: "array"
				items: type: "string"
				description: "Additional keywords to add"
				default: []
			}
		}
		required: ["url"]
	}
}

// =============================================================================
// f/tandoor/batch_import_recipes
// Import multiple recipes from newline-separated URLs
// =============================================================================

#BatchImportRecipesFlowInput: {
	urls:                 string         // newline-separated URLs
	additional_keywords?: [...string]    // tags for all recipes, default []
}

#BatchImportRecipesFlowOutput: {
	import_each: [...#ImportRecipeFlowOutput]  // results per URL
}

#BatchImportRecipesFlow: {
	summary:     "Batch import recipes from URLs"
	description: string
	value: {
		modules: [
			{
				id: "import_each"
				value: {
					type: "forloopflow"
					iterator: {
						type: "javascript"
						expr: "flow_input.urls.split('\\n').map(u => u.trim()).filter(u => u.length > 0)"
					}
					skip_failures: true
					parallel:      false
					parallelism:   1
					modules: [
						{
							id: "import"
							value: {
								type: "flow"
								path: "f/tandoor/import_recipe"
								input_transforms: {
									url: {
										type: "javascript"
										expr: "flow_input.iter.value"
									}
									additional_keywords: {
										type: "javascript"
										expr: "flow_input.additional_keywords || []"
									}
								}
							}
						},
					]
				}
			},
		]
	}
	schema: {
		"$schema": "https://json-schema.org/draft/2020-12/schema"
		type:      "object"
		properties: {
			urls: {
				type:        "string"
				description: "Recipe URLs (one per line)"
				format:      "textarea"
			}
			additional_keywords: {
				type: "array"
				items: type: "string"
				description: "Additional keywords to add to all recipes"
				default: []
			}
		}
		required: ["urls"]
	}
}
