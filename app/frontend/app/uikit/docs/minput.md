 ### example

Simple
```vue
  <m-input label="Simple" />
```

Required and email
```vue
  <m-input label="Email" :required="true" type="email" />
```

Disabled
```vue
  <m-input label="disabled" :disabled="true" value="Disabled text" />
```

Counter
```vue
  <m-input label="Counter" :maxCounter="20" />
```

Description with counter
```vue
  <m-input label="Label" description="Helper description" :maxCounter="20" />
```

Pure text input
```vue
 <m-input :pure="true" placeholder="Pure input" />
```

Validation, click for demo
```vue
 <m-input label="Validation" rules="required|email" />
```