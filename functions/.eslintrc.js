module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files.
    "/generated/**/*", // Ignore generated files.
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": ["error", "double"],
    "import/no-unresolved": 0,
    "indent": ["error", 2], // Asegura indentación de 2 espacios
    "max-len": ["off"], // <--- DESHABILITADO: Ignora la longitud de línea
    "object-curly-spacing": ["off"], // <--- DESHABILITADO: Ignora espacios en llaves de objetos
    "linebreak-style": ["off"], // <--- DESHABILITADO: Ignora el estilo de salto de línea (CRLF vs LF)
    "no-trailing-spaces": ["off"], // <--- DESHABILITADO: Ignora espacios al final de la línea
    "@typescript-eslint/no-explicit-any": "off", // <--- DESHABILITADO: Permite el uso de 'any'
  },
};
