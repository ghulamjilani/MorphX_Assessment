### Example

Default table

```vue
<m-table>
  <thead>
    <tr>
      <th>ID</th>
      <th>Name</th>
      <th>Addres</th>
      <th>Job title</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>Minnie Cruickshank</td>
      <td>45809 Linnie Ridges</td>
      <td>Regional Branding Representative</td>
      <td>
        <div>
          <m-btn type="main" size="s" :square="false">Delete</m-btn>
        </div>
      </td>
    </tr>
    <tr>
      <td>2</td>
      <td>Brent Schultz</td>
      <td>301 Donato Gateway</td>
      <td>Human Web Architect</td>
      <td>
        <div>
          <m-btn type="main" size="s" :square="false">Delete</m-btn>
        </div>
      </td>
    </tr>
    <tr>
      <td>3</td>
      <td>Ms. Mack Dietrich</td>
      <td>21052 Anderson Squares</td>
      <td>Future Implementation Developer</td>
      <td>
        <div>
          <m-btn type="main" size="s" :square="false">Delete</m-btn>
        </div>
      </td>
    </tr>
  </tbody>
</m-table>
```

Bordered, bold headers, min width 70rem, no collapse

```vue
<m-table bordered="all" thFontWeight="bold" minWidth="70rem" tableCollapse="none">
  <thead>
    <tr>
      <th>ID</th>
      <th>Name</th>
      <th>Addres</th>
      <th>Job title</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>Minnie Cruickshank</td>
      <td>45809 Linnie Ridges</td>
      <td>Regional Branding Representative</td>
      <td>
        <div>
          <m-btn type="main" size="s" :square="false">Delete</m-btn>
        </div>
      </td>
    </tr>
    <tr>
      <td>2</td>
      <td>Brent Schultz</td>
      <td>301 Donato Gateway</td>
      <td>Human Web Architect</td>
      <td>
        <div>
          <m-btn type="main" size="s" :square="false">Delete</m-btn>
        </div>
      </td>
    </tr>
    <tr>
      <td>3</td>
      <td>Ms. Mack Dietrich</td>
      <td>21052 Anderson Squares</td>
      <td>Future Implementation Developer</td>
      <td>
        <div>
          <m-btn type="main" size="s" :square="false">Delete</m-btn>
        </div>
      </td>
    </tr>
  </tbody>
</m-table>
```