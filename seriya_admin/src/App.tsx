import { useEffect, useMemo, useState } from 'react'
import {
  Activity,
  BusFront,
  Check,
  CheckCircle2,
  ChevronDown,
  Clock3,
  LayoutDashboard,
  Eye,
  EyeOff,
  LockKeyhole,
  LogOut,
  Mail,
  Menu,
  RefreshCw,
  Route,
  Search,
  ShieldCheck,
  UserCheck,
  UserRound,
  Users,
  X,
  XCircle,
} from 'lucide-react'
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth'
import {
  collection,
  doc,
  getDoc,
  onSnapshot,
  serverTimestamp,
  updateDoc,
  type Timestamp,
} from 'firebase/firestore'

import './App.css'
import { auth, db } from './firebase'

type AccountStatus = 'pending' | 'approved' | 'rejected' | 'disabled'
type Role = 'passenger' | 'driver' | 'admin'

interface UserProfile {
  id: string
  fullName: string
  employeeId: string
  phone: string
  email?: string | null
  requestedRole: 'passenger' | 'driver'
  approvedRole?: Role | null
  status: AccountStatus
  createdAt?: Timestamp | null
}

type Filter = 'all' | AccountStatus

function App() {
  const [authLoading, setAuthLoading] = useState(true)
  const [admin, setAdmin] = useState<User | null>(null)
  const [authError, setAuthError] = useState('')

  useEffect(() => {
    return onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setAdmin(null)
        setAuthLoading(false)
        return
      }

      try {
        const profile = await getDoc(doc(db, 'users', user.uid))
        const data = profile.data()
        if (
          !profile.exists() ||
          data?.status !== 'approved' ||
          data?.approvedRole !== 'admin'
        ) {
          await signOut(auth)
          setAuthError('This account does not have administrator access.')
          setAdmin(null)
        } else {
          setAdmin(user)
          setAuthError('')
        }
      } catch {
        await signOut(auth)
        setAuthError('Admin access could not be verified. Please try again.')
      } finally {
        setAuthLoading(false)
      }
    })
  }, [])

  if (authLoading) return <SplashScreen />

  if (!admin) {
    return <AdminLogin initialError={authError} />
  }

  return <Dashboard admin={admin} />
}

function SplashScreen() {
  return (
    <main className="splash-screen">
      <BrandMark />
      <div className="spinner" aria-label="Loading" />
    </main>
  )
}

function AdminLogin({ initialError }: { initialError: string }) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(initialError)

  async function signIn(event: React.FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    try {
      await signInWithEmailAndPassword(
        auth,
        username.trim().toLowerCase(),
        password,
      )
    } catch {
      setError('The username or password is incorrect.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <main className="login-page">
      <section className="login-story" aria-label="Seriya administration">
        <div className="story-content">
          <BrandMark inverse />
          <div className="story-copy">
            <span className="eyebrow">Transport operations</span>
            <h1>Keep every team moving, safely and on time.</h1>
            <p>
              Review employee access, coordinate drivers, and manage daily
              transport operations from one secure workspace.
            </p>
          </div>
          <div className="story-stats">
            <div>
              <ShieldCheck size={22} />
              <span>Secure admin access</span>
            </div>
            <div>
              <Activity size={22} />
              <span>Live operations view</span>
            </div>
          </div>
        </div>
      </section>

      <section className="login-panel">
          <div className="login-card">
          <div className="mobile-brand"><BrandMark /></div>
          <span className="eyebrow teal">Admin portal</span>
          <h2>Welcome back</h2>
          <p className="muted">
            Sign in with the username and password assigned to your administrator account.
          </p>

          {error && (
            <div className="alert" role="alert">
              <XCircle size={18} />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={signIn}>
              <label htmlFor="username">Username</label>
              <div className="input-wrap">
                <Mail size={19} />
                <input
                  id="username"
                  type="email"
                  value={username}
                  onChange={(event) => setUsername(event.target.value)}
                  placeholder="admin@seriya.lk"
                  autoComplete="username"
                  required
                />
              </div>
              <label className="password-label" htmlFor="password">Password</label>
              <div className="input-wrap">
                <LockKeyhole size={19} />
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  placeholder="Enter your password"
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowPassword((value) => !value)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
              <button className="primary-button" disabled={busy}>
                {busy ? <RefreshCw className="spin" size={18} /> : <ShieldCheck size={18} />}
                {busy ? 'Signing in…' : 'Sign in to dashboard'}
              </button>
          </form>

          <div className="security-note">
            <ShieldCheck size={18} />
            Access is restricted to approved Seriya administrators.
          </div>
        </div>
      </section>
    </main>
  )
}

function Dashboard({ admin }: { admin: User }) {
  const [users, setUsers] = useState<UserProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState<Filter>('pending')
  const [updatingId, setUpdatingId] = useState('')
  const [sidebarOpen, setSidebarOpen] = useState(false)

  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, 'users'),
      (snapshot) => {
        const profiles = snapshot.docs.map((snapshotDoc) => ({
          id: snapshotDoc.id,
          ...snapshotDoc.data(),
        })) as UserProfile[]
        profiles.sort(
          (a, b) =>
            (b.createdAt?.toMillis?.() ?? 0) - (a.createdAt?.toMillis?.() ?? 0),
        )
        setUsers(profiles)
        setLoading(false)
        setError('')
      },
      () => {
        setError('User registrations could not be loaded. Check Firestore rules.')
        setLoading(false)
      },
    )
    return unsubscribe
  }, [])

  const counts = useMemo(() => {
    const employeeUsers = users.filter((user) => user.approvedRole !== 'admin')
    return {
      all: employeeUsers.length,
      pending: employeeUsers.filter((user) => user.status === 'pending').length,
      approved: employeeUsers.filter((user) => user.status === 'approved').length,
      drivers: employeeUsers.filter(
        (user) =>
          user.status === 'approved' &&
          (user.approvedRole ?? user.requestedRole) === 'driver',
      ).length,
    }
  }, [users])

  const visibleUsers = useMemo(() => {
    const term = search.trim().toLowerCase()
    return users.filter((user) => {
      if (user.approvedRole === 'admin') return false
      const matchesFilter = filter === 'all' || user.status === filter
      const matchesSearch =
        !term ||
        user.fullName?.toLowerCase().includes(term) ||
        user.employeeId?.toLowerCase().includes(term) ||
        user.phone?.includes(term)
      return matchesFilter && matchesSearch
    })
  }, [filter, search, users])

  async function updateAccount(user: UserProfile, status: 'approved' | 'rejected') {
    setUpdatingId(user.id)
    setError('')
    try {
      await updateDoc(doc(db, 'users', user.id), {
        status,
        approvedRole: status === 'approved' ? user.requestedRole : null,
        updatedAt: serverTimestamp(),
      })
    } catch {
      setError('The account could not be updated. Please try again.')
    } finally {
      setUpdatingId('')
    }
  }

  return (
    <div className="admin-shell">
      <aside className={sidebarOpen ? 'sidebar open' : 'sidebar'}>
        <div className="sidebar-head">
          <BrandMark inverse />
          <button className="icon-button mobile-close" onClick={() => setSidebarOpen(false)}>
            <X size={20} />
          </button>
        </div>
        <nav>
          <button className="nav-item active"><LayoutDashboard size={19} />Overview</button>
          <button className="nav-item"><Users size={19} />People<span>{counts.pending}</span></button>
          <button className="nav-item disabled"><BusFront size={19} />Vehicles<small>Soon</small></button>
          <button className="nav-item disabled"><Route size={19} />Routes<small>Soon</small></button>
        </nav>
        <div className="sidebar-foot">
          <div className="admin-avatar">{initials(admin.displayName || 'Admin')}</div>
          <div><strong>{admin.displayName || 'Administrator'}</strong><span>System administrator</span></div>
          <button className="icon-button dark" onClick={() => signOut(auth)} title="Sign out">
            <LogOut size={18} />
          </button>
        </div>
      </aside>

      {sidebarOpen && <button className="sidebar-backdrop" onClick={() => setSidebarOpen(false)} />}

      <main className="dashboard-main">
        <header className="topbar">
          <button className="icon-button menu-button" onClick={() => setSidebarOpen(true)}>
            <Menu size={21} />
          </button>
          <div>
            <span className="breadcrumb">Seriya / Administration</span>
            <h1>Good day, Administrator</h1>
          </div>
          <div className="system-status"><span />All systems operational</div>
        </header>

        <div className="dashboard-content">
          <section className="metric-grid" aria-label="Account summary">
            <MetricCard label="Pending review" value={counts.pending} icon={<Clock3 />} tone="amber" />
            <MetricCard label="Approved users" value={counts.approved} icon={<UserCheck />} tone="teal" />
            <MetricCard label="Active drivers" value={counts.drivers} icon={<BusFront />} tone="blue" />
            <MetricCard label="Total accounts" value={counts.all} icon={<Users />} tone="purple" />
          </section>

          <section className="panel">
            <div className="panel-heading">
              <div>
                <span className="eyebrow teal">Access management</span>
                <h2>User registrations</h2>
                <p>Review employee requests and assign their approved access.</p>
              </div>
              <div className="toolbar">
                <div className="search-box">
                  <Search size={18} />
                  <input
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Search name, ID or phone"
                  />
                </div>
                <div className="select-wrap">
                  <select value={filter} onChange={(event) => setFilter(event.target.value as Filter)}>
                    <option value="all">All accounts</option>
                    <option value="pending">Pending</option>
                    <option value="approved">Approved</option>
                    <option value="rejected">Rejected</option>
                    <option value="disabled">Disabled</option>
                  </select>
                  <ChevronDown size={16} />
                </div>
              </div>
            </div>

            {error && <div className="alert table-alert"><XCircle size={18} />{error}</div>}

            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Employee</th>
                    <th>Requested access</th>
                    <th>Contact</th>
                    <th>Registered</th>
                    <th>Status</th>
                    <th><span className="sr-only">Actions</span></th>
                  </tr>
                </thead>
                <tbody>
                  {visibleUsers.map((user) => (
                    <tr key={user.id}>
                      <td>
                        <div className="person-cell">
                          <div className="person-avatar">{initials(user.fullName)}</div>
                          <div><strong>{user.fullName}</strong><span>ID {user.employeeId}</span></div>
                        </div>
                      </td>
                      <td><span className={`role-pill ${user.requestedRole}`}><UserRound size={14} />{capitalize(user.requestedRole)}</span></td>
                      <td><div className="contact-cell"><strong>{user.phone}</strong><span>{user.email || 'No email provided'}</span></div></td>
                      <td>{formatDate(user.createdAt)}</td>
                      <td><StatusBadge status={user.status} /></td>
                      <td>
                        {user.status === 'pending' ? (
                          <div className="row-actions">
                            <button
                              className="approve-button"
                              disabled={updatingId === user.id}
                              onClick={() => updateAccount(user, 'approved')}
                            ><Check size={16} />Approve</button>
                            <button
                              className="reject-button"
                              disabled={updatingId === user.id}
                              onClick={() => updateAccount(user, 'rejected')}
                              title="Reject"
                            ><X size={17} /></button>
                          </div>
                        ) : (
                          <span className="completed-action"><CheckCircle2 size={16} />Reviewed</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {!loading && visibleUsers.length === 0 && (
              <div className="empty-state">
                <UserCheck size={32} />
                <h3>No matching registrations</h3>
                <p>New registration requests will appear here automatically.</p>
              </div>
            )}
            {loading && <div className="loading-row"><RefreshCw className="spin" size={20} />Loading registrations…</div>}
          </section>
        </div>
      </main>
    </div>
  )
}

function MetricCard({ label, value, icon, tone }: { label: string; value: number; icon: React.ReactNode; tone: string }) {
  return <article className="metric-card"><div className={`metric-icon ${tone}`}>{icon}</div><div><span>{label}</span><strong>{value}</strong></div></article>
}

function StatusBadge({ status }: { status: AccountStatus }) {
  return <span className={`status-badge ${status}`}><span />{capitalize(status)}</span>
}

function BrandMark({ inverse = false }: { inverse?: boolean }) {
  return <div className={inverse ? 'brand inverse' : 'brand'}><span><BusFront size={23} /></span><div><strong>SERIYA</strong><small>ADMIN CONSOLE</small></div></div>
}

function initials(value: string) {
  return value.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join('').toUpperCase() || 'A'
}

function capitalize(value: string) {
  return value.charAt(0).toUpperCase() + value.slice(1)
}

function formatDate(value?: Timestamp | null) {
  if (!value?.toDate) return '—'
  return new Intl.DateTimeFormat('en-LK', { day: '2-digit', month: 'short', year: 'numeric' }).format(value.toDate())
}

export default App
