---
layout: post
title:  "NestJS DB config that plays well with migrations"
date:   2021-03-01 07:00:00 +0100
published: true
categories: javascript typescript nestjs typeorm development
image: assets/images/nestjs.png
---

### Synopsis

If you've found this page, chances are that you are wanting to set up database configurations for NestJS, that also work for your TypeORM migrations.

You want to have different environments for `development`, `test` and `production`, and easily switch between them. When you run your migrations, you want to specify the environment in the same way.
And you definitely *don't* want to write your DB config multiple times.

Well, you've come to the right place!

*tl;dr: There is a working example in the [repo link](https://github.com/ronen-agranat/f2f-server) at the end.*

### What is NestJS?

Recently, I've been experimenting with various state-of-the-art technologies for writing modern web applications.
NestJS is a progressive framework for creating applications in TypeScript.
It combines progressive JavaScript with essential functionality found in mature alternatives such as Ruby on Rails, Django (Python), and Spring for Java.
I've found it to be a compelling option for writing services in 2021.

The frameworks mentioned above tend to offer similar functionality.
In particular:

* Object-relational mapping (ORM)
* Database migrations
* Environment configuration

Let's look at these in more detail.

### What is an ORM?

A key feature of all the above frameworks is that they provide an object-relational mapper (ORM).
An ORM removes database boilerplate from an application.
It does this by mapping the applications data models and operations directly to the corresponding SQL (or similar).
This means that you, the developer, need to specify the model only once, as application source code, rather than twice: as source code, and then again as SQL (or similar).
This DRYs up the code (Don't Repeat Yourself), simplifying refactoring, while reducing human error and gruntwork..

### What are migrations?

It's also common for such frameworks to provide "migrations".
Migrations are scripts that, when executed in sequence, bring the database into the same state as the application, so that the database schema matches the application's data models.
Migrations are created and run after changing the applications data models; for example, after creating or changing `Entities` in NestJS.

### Specifying different environments

These frameworks typically provide the ability to specify and switch between different "environments", such as `development`, `test` and `production`.
This makes it convenient for you, the developer, to run the local application against different environments as needed, as well as to run operations against these environments, such as migrations.

### The problem

A [common](https://github.com/nestjs/typeorm/issues/33) [struggle](https://github.com/nestjs/docs.nestjs.com/pull/427) [people](https://jaketrent.com/post/configure-typeorm-inject-nestjs-config) have with NestJS is that it's not clear how to specify different DB config environments and have them be respected by both the NestJS application and TypeORM migrations.

NestJS does provide a configuration library called `@nestjs/config` – but it doesn't solve this problem.
It's more concerned with providing flexible configuration to the application code within NestJS itself, and it's not a good fit for configuring TypeORM, as you can see in the gymnastics and confusion in the threads mentioned above.

We can be forgiven for this confusion, because in frameworks such as Ruby on Rails, managing multiple DB configurations is *exactly* the problem the configuration library is designed to solve; just not in NestJS.

### The solution.

Fortunately, there is a simple solution that uses `dotenv` directly, which `@nestjs/config` is built on, without requiring `@nestjs/config` at all.

### Create .env files

First, create some `.env` files in your project root directory, specifying your [database config](https://github.com/typeorm/typeorm/blob/master/docs/using-ormconfig.md).
Call them `.dev.env` and `.prod.env`.
`.dev.env` will have our local MySQL DB creds, and `.prod.env` will have our production database creds.

Populate the two files as follows:

```bash
TYPEORM_USERNAME=<username>
TYPEORM_PASSWORD=<password>
TYPEORM_HOST=<host>
```

*Note that you can include other environment variables and name these files as you please*

### Create DB configuration

Then, create the following file to represent your DB config, in your project's `src` folder:

```typescript
import * as path from 'path';
import * as dotenv from 'dotenv';

const env = process.env.NODE_ENV || 'dev';
const dotenv_path = path.resolve(process.cwd(), `.${env}.env`);
const result = dotenv.config({ path: dotenv_path });
if (result.error) { /* do nothing */ }

export const DatabaseConfig = {
  type: 'mysql' as any,
  driver: 'mysql',
  database: process.env.TYPEORM_DATABASE || 'your_database_name',
  port: parseInt(process.env.TYPEORM_PORT) || 3306,
  username: process.env.TYPEORM_USERNAME,
  password: process.env.TYPEORM_PASSWORD,
  host: process.env.TYPEORM_HOST,
  synchronize: false,
  migrationsRun: false,
  entities: ["dist/**/*.entity{.ts,.js}"],
  migrations: ["dist/migrations/**/*{.ts,.js}"],
  cli: { "migrationsDir": "src/migrations" }
}

export default DatabaseConfig;
```

*Of course, you can customise the actual DB config to your heart's content.*

These are the key lines:

```typescript
const env = process.env.NODE_ENV || 'dev';
const dotenv_path = path.resolve(process.cwd(), `.${env}.env`);
const result = dotenv.config({ path: dotenv_path });
if (result.error) { /* do nothing */ }
```

This will look at the `NODE_ENV` environment variable and use `dotenv` to load the corresponding `.env` file so that the key/value pairs are available throughout your application as though they were normal environment variables.
Then they are simply referenced in the database configuration.
This is then exported 'nicely' (by name) for inclusion into the NestJS app module, as well as 'by default' to provide it as a config file to `typeorm` directly.

### Include the database config in your app module

In `app.module.ts`, import this database config as follows:

```typescript
import { DatabaseConfig } from './config/database.config';
```

And reference it in the `TypeOrmModule` import for `AppModule`.

```typescript
@Module({
  imports: [
    // ...
    TypeOrmModule.forRoot(DatabaseConfig)
    // ...
  ],
  // ...
})
export class AppModule {}
```

This connects your NestJS application to the database configuration.

### How to use

#### Running application locally

Now, when you run your application as usual:

    $ nest start

It will load your creds from `.dev.env`

This is the same as:

    $ NODE_ENV=dev nest start

because `dev` is the default environment (you can change this).

#### Running migrations locally

You can run your migrations locally like so:

    $ npx ts-node ./node_modules/typeorm/cli.js migration:run --config src/config/database.config

This is the same as 

    $ NODE_ENV=dev npx ts-node ./node_modules/typeorm/cli.js migration:run --config src/config/database.config

Here we are pointing TypeORM to the same database configuration file that we created earlier, which is the same file that is used by NestJS.

*Is the incantation a mouthful? See the reasoning at the end of the article. You can put this into a package.json build script for neatness*

#### Running application against production

Run your local application against the production environment like so:

    $ NODE_ENV=prod nest start

and it will connect to your production database because it loads creds from `.prod.env`.

#### Run migrations against production

You can also run your migrations against production like so:

    $ NODE_ENV=prod npx ts-node ./node_modules/typeorm/cli.js migration:run --config src/config/database.config

The objective is achieved: the environment is specified in the same way for the application as for migrations, and you only had to specify the config once. And it's just 4 lines of verbose code.

### Working example

Please see a complete working implementation here, in my Face-to-Face server repo:
https://github.com/ronen-agranat/f2f-server

### Some more details

Under no circumstances should these `.env` files be checked into source control! In fact, they should be added to your `.gitignore` file to prevent this. This is because you never want to check creds into source control.

In your actual test pipeline and production deployment, you would specify the database credentials directly as environment variables, and not use the scheme mentioned in this article at all.

It's no problem if the `.env` file is not present.
Then this convenience logic simply does nothing.
For example, this would be the case in your test pipeline or production environment, where you set environment directly in Github, AWS Lambda, Netlify, etc, and not through `.env` files.

**Note**: `dotenv` favours actual environment variables over the values specified in the file, so be sure to unset those.

### What's up with the complicated incantation for running migrations?

- `npx` will look for the subsequent commands in the npm path or install them if needed

- `ts-node` is used to run TypeORM since we're using TypeScript

And that's all there is to it!

### Conclusion

So you can see, it's actually very easy to have one DB configuration for NestJS that also applies to running your TypeORM migrations, if you use `dotenv` instead of `@nestjs/config`.

The relative simplicity illustrates that managing different DB configuration environments is probably not the primary problem that `@nestjs/config` was designed to solve. In my opinion, a lot of the confusion results from the fact that this is exactly the problem that environment configurations primarily solve in other similar frameworks; just not in NestJS.

I hope you found this helpful and that it saved you some time! Please leave a comment because I would love to hear from you. Until next time!