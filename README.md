# Recipe Email Sender

A Go application that selects random recipes from YAML files and sends them via email using the Mailtrap API. This tool is perfect for meal planning, recipe sharing, or integrating into a larger kitchen management system.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
  - [.env File](#env-file)
  - [Recipe Files](#recipe-files)
- [Usage](#usage)
- [Testing](#testing)
- [Sample Output](#sample-output)
- [Dependencies](#dependencies)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Random Recipe Selection**: Randomly selects a specified number of recipes from provided YAML files.
- **Email Integration**: Sends the selected recipes via email using the Mailtrap API.
- **Secure Configuration**: Utilizes environment variables to manage sensitive information securely.
- **Flexible Recipe Management**: Easily add, remove, or modify recipes by editing YAML files.
- **Simple Recipes**: All recipes have 5 ingredients or less for easy preparation.


## Prerequisites

- **Go**: Ensure you have Go installed (version 1.23 or later recommended). [Download Go](https://golang.org/dl/)
- **Mailtrap Account**: Sign up for a [Mailtrap](https://mailtrap.io/) account to obtain an API token for sending emails.
- **Git**: For version control and cloning the repository. [Download Git](https://git-scm.com/downloads)

## Installation

1. **Clone the Repository**

```bash
   git clone https://github.com/lprior-repo/meal-planner
   cd meal-planner
```

2. **Install the dependencies**
`go get github.com/joho/godotenv`
`go get gopkg.in/yaml.v3`

Description of Variables:

- MAILTRAP_API_TOKEN: Your Mailtrap API token for authentication.
- SENDER_EMAIL: The email address from which the email will be sent.
- SENDER_NAME: The name associated with the sender email.
- RECIPIENT_EMAIL: The email address where the recipes will be sent.

## 3. **Run the Program**

`go run main.go`

## Testing

The project uses the Testing Trophy approach with multiple levels of tests:

### Running Tests

Use the provided Makefile to run tests:

```bash
# Run all tests
make test

# Run specific test levels
make test-unit
make test-integration
make test-e2e

# Run linter
make lint

# Build and run the application
make build
make run
```

### Test Structure

- **Static Tests (Linting)**: Uses golangci-lint to check code quality
- **Unit Tests**: Tests individual functions in isolation
- **Integration Tests**: Tests how components work together
- **End-to-End Tests**: Tests the entire application workflow

### GitHub Actions

This project uses GitHub Actions for continuous integration, automatically running tests on every push to the main branch and pull requests.

## Sample Output

```yaml
Recipe 1: Simple Beef Stir-Fry
  - beef sirloin, sliced: 2 lbs
  - broccoli florets: 2 cups
  - soy sauce: 1/4 cup
  - sesame oil: 2 tbsp
  - garlic, minced: 2 cloves
  * Mix soy sauce, sesame oil, and garlic.
  * Toss beef slices in the mixture.
  * Arrange beef and broccoli on a baking sheet.
  * Bake at 400°F for 20-25 minutes, stirring halfway through.

------------------------------------------------

Recipe 2: Lemon Garlic Shrimp
  - shrimp, peeled and deveined: 2 lbs
  - lemon juice: 1/4 cup
  - garlic cloves, minced: 4
  - butter: 3 tbsp
  - salt: 1 tsp
  * Mix lemon juice and garlic in a bowl.
  * Toss shrimp in the mixture with salt.
  * Heat butter in a skillet.
  * Cook shrimp for 1-2 minutes per side until pink.
  * Serve hot.

------------------------------------------------

Recipe 3: Simple Pork and Beans
  - bacon, diced: 1 lb
  - canned beans: 2 cans (15 oz each)
  - ketchup: 1/2 cup
  - molasses: 1/4 cup
  - brown sugar: 2 tbsp
  * Cook bacon in skillet until crisp.
  * Add beans, ketchup, molasses, and brown sugar.
  * Stir to combine.
  * Bake at 350°F covered for 30 minutes, then uncovered for 15 minutes.
  * Let rest before serving.

------------------------------------------------

Recipe 4: Simple Smoked Turkey Breast
  - turkey breast: 5 lbs
  - honey: 2 tbsp
  - Dijon mustard: 2 tbsp
  - salt: 1 tbsp
  - garlic powder: 1 tbsp
  * Preheat smoker to 250°F.
  * Mix honey, Dijon mustard, salt, and garlic powder.
  * Rub mixture all over turkey breast.
  * Smoke until internal temperature reaches 165°F.
  * Let rest for 15 minutes before slicing.
```

