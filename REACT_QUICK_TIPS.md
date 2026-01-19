# Quick React Tips for Enterprise Code (USCIS/Global)

## 1. Component Structure You'll See

```javascript
// Most common: Functional component with hooks
function CaseDetail({ caseId }) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  
  useEffect(() => {
    // Fetch on mount
  }, [caseId])
  
  if (loading) return <div>Loading...</div>
  return <div>{data}</div>
}

export default CaseDetail
```

**What to look for:**
- `useState(initialValue)` → Returns `[value, setValue]` 
- `useEffect(() => {...}, [deps])` → Runs when deps change
- Always return JSX (looks like HTML but it's JavaScript)

---

## 2. The Three-Step React Pattern (80% of code)

```javascript
// STEP 1: Get data from API
useEffect(() => {
  fetch('/api/v1/cases/123')
    .then(r => r.json())
    .then(d => setData(d.data))  // ← Store in state
}, [])

// STEP 2: User does something
function handleUpdate(newStatus) {
  fetch('/api/v1/cases/123', {
    method: 'PATCH',
    body: JSON.stringify({ status: newStatus })
  })
  .then(r => r.json())
  .then(d => setData(d.data))  // ← Update state with new data
}

// STEP 3: Render based on state
return (
  <div>
    <h1>{data.case_number}</h1>
    <select onChange={(e) => handleUpdate(e.target.value)}>
      <option>Submitted</option>
      <option>In Review</option>
    </select>
  </div>
)
```

**Pattern**: Fetch → Store → Render → User Action → Fetch → Update → Render

---

## 3. Common Hooks (You'll See These Constantly)

```javascript
// useState - Store data
const [count, setCount] = useState(0)
setCount(count + 1)  // Update it

// useEffect - Run code after render
useEffect(() => {
  console.log('Component mounted or deps changed')
}, [dependency1, dependency2])

// useContext - Share data across components
const theme = useContext(ThemeContext)

// useReducer - Complex state (Redux-lite)
const [state, dispatch] = useReducer(reducer, initialState)
dispatch({ type: 'INCREMENT' })

// useMemo - Cache expensive calculations
const expensive = useMemo(() => {
  return verySlowFunction(data)
}, [data])  // Only recalculate if data changes

// useCallback - Cache function references
const handleClick = useCallback(() => {
  doSomething()
}, [dependency])
```

---

## 4. Props (How Components Talk)

```javascript
// Parent component
function CaseList() {
  const cases = [...]
  return (
    <div>
      {cases.map(c => (
        // Passing data DOWN (props)
        <CaseCard 
          key={c.id} 
          caseId={c.id}
          status={c.status}
          onStatusChange={(newStatus) => handleUpdate(newStatus)}
        />
      ))}
    </div>
  )
}

// Child component
function CaseCard({ caseId, status, onStatusChange }) {
  return (
    <div>
      <h3>Case {caseId}</h3>
      <p>Status: {status}</p>
      {/* Calling function UP (callback) */}
      <button onClick={() => onStatusChange('approved')}>
        Approve
      </button>
    </div>
  )
}
```

**Rule**: Data flows DOWN (props), events flow UP (callbacks)

---

## 5. Lists & Keys (Critical for Enterprise)

```javascript
// ❌ WRONG - No key
{cases.map((c, index) => (
  <CaseRow key={index} case={c} />  // BAD!
))}

// ✅ RIGHT - Use unique ID
{cases.map(c => (
  <CaseRow key={c.id} case={c} />  // GOOD
))}
```

**Why**: React uses keys to track which item is which. Without proper keys, state gets mixed up when you add/remove items.

---

## 6. Forms (You'll Do This a Lot)

```javascript
function CaseForm() {
  const [formData, setFormData] = useState({
    status: '',
    notes: '',
    dueDate: ''
  })

  function handleChange(e) {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  function handleSubmit(e) {
    e.preventDefault()  // Prevent page reload
    // Send formData to API
    fetch('/api/v1/cases/123', {
      method: 'PATCH',
      body: JSON.stringify(formData)
    })
  }

  return (
    <form onSubmit={handleSubmit}>
      <select name="status" value={formData.status} onChange={handleChange}>
        <option>Submitted</option>
        <option>Approved</option>
      </select>
      <textarea name="notes" value={formData.notes} onChange={handleChange} />
      <button type="submit">Save</button>
    </form>
  )
}
```

**Pattern**: Form inputs → state → user submits → API call

---

## 7. Error Handling (Critical in Enterprise)

```javascript
function CaseDetail({ caseId }) {
  const [data, setData] = useState(null)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch(`/api/v1/cases/${caseId}`)
      .then(r => {
        if (!r.ok) throw new Error(`API error: ${r.status}`)
        return r.json()
      })
      .then(d => setData(d.data))
      .catch(e => setError(e.message))  // ← Catch errors!
      .finally(() => setLoading(false))
  }, [caseId])

  if (loading) return <div>Loading...</div>
  if (error) return <div style={{color: 'red'}}>Error: {error}</div>
  if (!data) return <div>No data</div>
  return <div>{data.case_number}</div>
}
```

**Always handle**: Loading → Error → Empty → Success

---

## 8. Performance Red Flags to Watch For

```javascript
// ❌ Creates new function every render (bad)
<button onClick={() => handleClick()}>Click</button>

// ✅ Use useCallback to memoize
const handleClick = useCallback(() => {
  doSomething()
}, [])
<button onClick={handleClick}>Click</button>

// ❌ Expensive operation in render (bad)
function Component() {
  const result = veryExpensiveCalculation()  // Runs every render!
  return <div>{result}</div>
}

// ✅ Use useMemo
function Component() {
  const result = useMemo(() => veryExpensiveCalculation(), [])
  return <div>{result}</div>
}

// ❌ Infinite loop (bad)
useEffect(() => {
  fetch(...).then(setData)
})  // No dependencies! Fetches every render

// ✅ Run once on mount
useEffect(() => {
  fetch(...).then(setData)
}, [])  // Empty deps = run once
```

---

## 9. Common Enterprise Libraries

```javascript
// HTTP requests (better than fetch)
import axios from 'axios'
axios.get('/api/cases').then(r => r.data)

// State management (for complex apps)
import { useSelector, useDispatch } from 'react-redux'
const cases = useSelector(state => state.cases)
dispatch(fetchCases())

// Routing (navigate between pages)
import { useNavigate } from 'react-router-dom'
const navigate = useNavigate()
navigate('/cases/123')

// Form handling (form management library)
import { useForm } from 'react-hook-form'
const { register, handleSubmit, watch } = useForm()

// UI components (pre-built, enterprise-grade)
import { Button, Modal, Table } from 'antd'  // or Material-UI
<Button type="primary">Submit</Button>

// Date handling
import { format, addDays } from 'date-fns'
format(new Date(), 'MMM dd, yyyy')
```

---

## 10. Quick Debug Checklist

When React code isn't working:

```javascript
// 1. Check the console for errors
// Open DevTools: F12 → Console tab

// 2. Add console.logs to trace execution
useEffect(() => {
  console.log('Component mounted')
  console.log('Data:', data)
}, [data])

// 3. Check React DevTools (browser extension)
// Shows component tree, state, props

// 4. Verify props are being passed
function CaseCard({ caseId }) {
  console.log('CaseCard props:', { caseId })  // What are we receiving?
  return <div>Case {caseId}</div>
}

// 5. Check state updates
const [data, setData] = useState(null)
console.log('State:', data)  // What's actually in state?

// 6. Verify API response
.then(r => {
  console.log('API response:', r)  // What did API send?
  return r.json()
})
```

---

## Quick Patterns at USCIS/Global

**You'll see:**
1. **Form + Table pattern** - List cases in table, click to edit in form
2. **Dashboard pattern** - Multiple widgets showing different data
3. **Workflow pattern** - Step-by-step process (submit → review → approve)
4. **Search + Filter pattern** - Search by case number, filter by status
5. **Real-time updates** - WebSocket subscriptions for status changes

**They all use**: useState → useEffect → fetch → render

---

## Resources to Learn

1. **React docs** (official): https://react.dev
2. **Interactive tutorial**: https://react.dev/learn
3. **Hooks guide**: https://react.dev/reference/react
4. **Common mistakes**: https://react.dev/learn/you-might-not-need-an-effect

**One tip**: Learn hooks first (modern React). Old class components are legacy.

---

That's 90% of React you'll encounter at enterprise! 🚀
