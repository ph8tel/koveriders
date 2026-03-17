# KoveRiders
This application allows riders to generate links that utilize Object Graph notation for creating image previews in social media posts. Users can upload images and relevant details, which can then be shared via a link at the end of their posts. This link generates a preview displaying the images and bike specifications.

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix

## Todo

- Resize images

## Data Structure

The application uses a relational database with the following key tables:

- **users**: Stores user information including authentication details.
- **user_bikes**: Contains information about bikes owned by users.
- **user_bike_images**: Holds images associated with each bike.
- **user_bike_mods**: Tracks modifications made to each bike.

## Pages

The application includes the following main pages:

- **Home**: Displays an overview of the application.
- **Garage**: Shows the user's bikes and their details.
- **Auth**: Handles user authentication, including login and registration.

## Authentication

The application uses Google OAuth for user authentication. Users can log in using their Google accounts, which provides a seamless experience.

## Routes

The following routes are defined in the application:

- **GET /**: Home page
- **GET /garage**: User's garage page displaying their bikes
- **POST /auth/google**: Initiates Google OAuth authentication
- **GET /auth/callback**: Handles the callback from Google after authentication
