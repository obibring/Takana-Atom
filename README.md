# Takana-Atom package

Takana integration for the Atom text editor.

## Installation

Using [apm](https://github.com/atom/apm):

```sh
apm install takana-atom
```

or clone this repository to your `~/.atom/packages` directory:

```sh
cd ~/.atom/packages
git clone git@github.com:obibring/Takana-Atom.git
```

## How To Use

`Takana-Atom` is activated automatically when Atom is launched. By default, `Takana-Atom` will attempt to connect
to the Takana editor server on its default port, `48627`. You can
override the port number using Package settings configuration (open your settings pane and find the `Takana-Atom` package).

### Reconnecting
Should Takana-Atom lose connection to your Takana Server, you can
attempt to reconnect to using
`Packages > Takana-Atom > Reconnect To Takana Server`. Once this
occurs, **you will need to reload your browser to resume live
previewing.**


## To Do
 - Tests
 - Display sass compilation errors in editor
