---
layout: post
title:  "Simple way to have common config for NestJS and migrations"
date:   2021-03-01 07:00:00 +0100
published: false
categories: javascript typescript nestjs typeorm development
image: assets/images/nestjs.png
---

### What is NestJS?

NestJS is a progressive framework for creating applications in TypeScript.
It combines state-of-the-art JavaScript with essential functionality found in mature alternatives such as Ruby on Rails, Django, Spring etc.
I've found it to be a compelling option for writing modern back-end services.

### Specifying different environments

It is common for frameworks to provide the ability to specify different "environments", such as development, test, production, etc., which can then easily be switched, for convenience, without needing to change a bunch of environment variables or configuration every time.

### What is an ORM?

Another key piece of the is the object-relational mapper or ORM, which removes a lot of the database boilerplate gruntwork from the application's data models, by inferring the correct database operations from the program code itself, reducing duplication (keeping it DRY) and toil.

### What are migrations?

It's also common for such frameworks to provide "migrations": sequences of scripts that synchronise the schema of the database with the data models of the application. These are created and run after adding or otherwise making changes to the models, which again reduces toil and gruntwork.

### The problem

A [common](https://github.com/nestjs/typeorm/issues/33) [struggle](https://github.com/nestjs/docs.nestjs.com/pull/427) [people](https://jaketrent.com/post/configure-typeorm-inject-nestjs-config) have is having migrations and environment config work together.

This brief article will present a simple solution for having multiple environments for your NestJS application, which also work for TypeORM migrations.
At first glance, this doesn't *seem* like it should be a problem. TypeORM itself is highly-configurable.

Now, NestJS does provide a configuration library aptly called `@nestjs/config`, but it is more concerned with providing configuration within the NestJS modules themselves, and is not really a good fit for providing database configuration to TypeORM. It can be done, but it starts to look a lot like fighting with the framework, in a way that is uncomfortably reminiscent of Spring annotation hell. And it is certainly not obvious how to have it play with TypeORM's migration commands without gymnastics.

### The solution.

The heart of the issue is that NestJS is intentionally kept as a separate concern from TypeORM, the underlying ORM which provides access to the data layer.

Fortunately, there is an extremely simple alternative, and it uses `dotenv`, which `@nestjs/config` is built on, without requiring `@nestjs/config` at all.

### Create .env files

First, in the vein of `dotenv`, create some `.env` files in your project root directory, specifying your (database config)[https://github.com/typeorm/typeorm/blob/master/docs/using-ormconfig.md]. We'll call them `.dev.env` and `.prod.env`; of course, you can name them whatever you like. `.dev.env` will have our local MySQL DB creds, and `.prod.env` will have our RDS instance hosted on Amazon AWS.

Populate them as follows:

```bash
TYPEORM_USERNAME=<username>
TYPEORM_PASSWORD=<password>
TYPEORM_HOST=<host>
```

You can feel free to include further environment variables here as you please.

Then, create the following file to represent your DB config, in your project's `src` folder:

### Create DB config

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

These are the key lines:

```typescript
const env = process.env.NODE_ENV || 'dev';
const dotenv_path = path.resolve(process.cwd(), `.${env}.env`);
const result = dotenv.config({ path: dotenv_path });
if (result.error) { /* do nothing */ }
```

This will look at the `NODE_ENV` environment variable and use `dotenv` to load the corresponding `.env` file so that the key/value pairs are available as though they were normal environment variables.
Then they are simply referenced to establish the database config.
This is then exported 'nicely' for inclusion into the app module, as well as 'by default' to provide it as a config file to `typeorm` directly.

### Include the database config in your app module

In `app.module.ts`, import the database config above:

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

### How to use

You can now run your application as usual:

    $ nest start

and it will connect to your local database because it loads creds from `.dev.env`

This is the same as:

    $ NODE_ENV=dev nest start

because `dev` is the default environment.

You can run your migrations locally like so:

    $ npx ts-node ./node_modules/typeorm/cli.js migration:run --config src/config/database.config

Run your application in the production environment like so:

    $ NODE_ENV=prod nest start

and it will connect to your production database because it loads creds from `.prod.env`.

You can also run your migrations against production like so:

    $ NODE_ENV=prod npx ts-node ./node_modules/typeorm/cli.js migration:run --config src/config/database.config

### Some more details

**Note**: `dotenv` favours actual environment variables over the values specified in the file, so be sure to unset those.

**Note**: Under no circumstances should these `.env` files be checked into source control! In fact, they should be added to your `.gitignore` file to prevent this. This is because you never want to check creds into source control.

It's no problem if the `.env` file is not present. Then this convenience logic simply does nothing. For example, this should be the case in your test pipeline or production environment, where you set environment directly in Github, AWS Lambda, Netlify, etc, and not through `.env` files.

### What's up with the complicated incantation for running migrations?

- `npx` will look for the subsequent commands in the npm path or even install them if needed

- `ts-node` is used to run TypeORM since we're using TypeScript and other niceties

- The final piece is specifying the common DB config script

And that's all there is to it!

### Conclusion

So you can see, it's actually very easy to have one DB configuration for NestJS that also applies to running your TypeORM migrations, if you use `dotenv` directly.
The relative simplicity illustrates that this is definitely not the problem that `@nestjs/config` was designed to solve. In my opinion, a lot of the confusion results from the fact that this is exactly the problem that environment configurations solve in other frameworks such as Ruby on Rails; just not in NestJS.

I hope you find this help and it saves you some time! I invite you to explore and compare this to some of the other alternative solutions mentioned at the beginning of this article for comparison. Please leave a comment because I would love to hear from you.