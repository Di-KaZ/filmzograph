# Filmzy 


#### UPDATE DOCKERFILE

With the dockerfile just use those two commands :

```bash
docker build -t filmzy .
docker run -it -p 8080:8080 --rm --name filmzy filmzy
```

then use insomnia collection to navigate or the swagger at `localhost:8080/index.html` (incomplete)

# Run the server

```
 📦 Install the dart_frog cli from pub.dev
dart pub global activate dart_frog_cli
```

```
dart run build_runner build
dart_frog dev
```

# Insomnia colleciton
There is an insomnia collection that you can import in it with all the endpoints of the api

~it was a bas idea to do this in dart~
