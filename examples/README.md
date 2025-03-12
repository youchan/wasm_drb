# wasm_drb examples

## How to run

Install rackup gem and bundle install

```
gem install rackup
bundle install
```

Build `ruby.wasm`

```
bundle exec rbwasm build -o dist/ruby.wasm
```

Pack source codes

```
bundle exec rbwasm pack dist/ruby.wasm --dir ./src::/src -o dist/app.wasm
```

Run rack application

```
rackup
```

Open the following URL on a browser and see developer console.
`http://localhost:9292`
