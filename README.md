# Recipe Email Sender

A Go application that selects random main and side dish recipes from YAML files and sends them via email using the Mailtrap API. This tool is perfect for meal planning, recipe sharing, or integrating into a larger kitchen management system.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
  - [.env File](#env-file)
  - [Recipe Files](#recipe-files)
- [Usage](#usage)
- [Sample Output](#sample-output)
- [Dependencies](#dependencies)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Random Recipe Selection**: Randomly selects a specified number of main and side dishes from provided YAML files.
- **Email Integration**: Sends the selected recipes via email using the Mailtrap API.
- **Secure Configuration**: Utilizes environment variables to manage sensitive information securely.
- **Flexible Recipe Management**: Easily add, remove, or modify recipes by editing YAML files.


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

## Output

```yaml
Main Dish 1: Sloppy Joes
  - 92% ground beef: 4 lbs
  - manwich sauce: 4
  - 80 calorie buns: 2
  - onion: 1
  * Brown the ground beef in a skillet.
  * Cut up the onions finely and add them to the beef.
  * Combine the beef with manwich sauce and stir well.
  * Place the mixture in a smoker at 250°f for 1-2 hours.

Side Dish 1: Sautéed Spinach
  - fresh spinach: 10 cups
  - garlic cloves, minced: 2
  - olive oil: 2 tbsp
  * Heat olive oil in a large skillet over medium heat.
  * Add minced garlic and sauté until fragrant, about 1 minute.
  * Add fresh spinach and toss until wilted, about 3-4 minutes.
  * Serve immediately.

------------------------------------------------

Main Dish 2: Easy Beef Bulgogi
  - beef ribeye, thinly sliced: 3 lbs
  - soy sauce: 1/2 cup
  - sesame oil: 2 tbsp
  - brown sugar: 2 tbsp
  - green onions, chopped: 1/2 cup
  * Preheat smoker/oven to 375°f.
  * In a bowl, mix soy sauce, sesame oil, brown sugar, and chopped green onions.
  * Toss beef slices in the marinade and let sit for 5 minutes.
  * Arrange beef on a baking sheet and bake for 20-25 minutes until cooked through.
  * Garnish with additional green onions if desired and serve over rice.

Side Dish 2: Garlic Butter Green Beans
  - green beans, trimmed: 4 cups
  - butter, melted: 3 tbsp
  - garlic cloves, minced: 2
  * Toss green beans with melted butter and minced garlic.
  * Spread on a baking sheet and roast at 400°f for 15 minutes until tender.
  * Serve warm.

------------------------------------------------

Main Dish 3: Grilled Pork Kebabs
  - pork loin, cubed: 2 lbs
  - bell peppers, cut into chunks: 2
  - red onion, cut into chunks: 1
  - teriyaki sauce: 1/2 cup
  - skewers: 10
  * Preheat grill to medium-high heat.
  * In a bowl, marinate pork cubes in teriyaki sauce for 15 minutes.
  * Thread pork, bell peppers, and onion onto skewers.
  * Grill skewers for 10-15 minutes, turning occasionally, until pork is cooked through.
  * Serve hot.

Side Dish 3: Simple Avocado Slices
  - avocados, sliced: 3
  - lime juice: 2 tbsp
  - sea salt: to taste
  * Arrange avocado slices on a plate.
  * Drizzle with lime juice and sprinkle with sea salt.
  * Serve immediately.

------------------------------------------------

Main Dish 4: Lemon Herb Chicken Breasts
  - chicken breasts: 4 lbs
  - lemon juice: 1/4 cup
  - garlic cloves, minced: 2
  - fresh rosemary, chopped: 2 tbsp
  * Preheat smoker/oven to 300°f.
  * In a bowl, combine lemon juice, minced garlic, and chopped rosemary.
  * Coat chicken breasts with the mixture.
  * Place in smoker/oven and cook until internal temperature reaches 165°f.

Side Dish 4: Cherry Tomato Basil Salad
  - cherry tomatoes, halved: 4 cups
  - fresh basil leaves, torn: 1/4 cup
  - mozzarella balls, halved: 2 cups
  * Combine halved cherry tomatoes, torn fresh basil leaves, and halved mozzarella balls in a bowl.
  * Toss gently to mix.
  * Serve fresh.
```

