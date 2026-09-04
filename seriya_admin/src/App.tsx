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
  Plus,
  Trash2,
  Pencil,
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
  addDoc,
  deleteDoc,
  query,
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

type VehicleStatus = 'active' | 'inactive' | 'maintenance'

interface Vehicle {
  id: string
  plateNumber: string
  displayName: string
  type: string
  capacity: number
  status: VehicleStatus
  assignedDriverId: string | null
  routeId: string | null
  createdAt?: Timestamp | null
  updatedAt?: Timestamp | null
}

type Filter = 'all' | AccountStatus
type Tab = 'overview' | 'people' | 'vehicles'

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
  const [currentTab, setCurrentTab] = useState<Tab>('overview')
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [vehiclesLoading, setVehiclesLoading] = useState(true)
  const [isAddingVehicle, setIsAddingVehicle] = useState(false)
  const [newVehicle, setNewVehicle] = useState({ plateNumber: '', displayName: '', type: 'van', capacity: 10 })
  const [assigningDriverVehicle, setAssigningDriverVehicle] = useState<Vehicle | null>(null)
  const [isAddingMockUser, setIsAddingMockUser] = useState(false)
  const [newMockUser, setNewMockUser] = useState({ fullName: '', phoneNumber: '', email: '', role: 'driver' })
  const [editingUser, setEditingUser] = useState<UserProfile | null>(null)
  const [isSaving, setIsSaving] = useState(false)
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

  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, 'vehicles'),
      (snapshot) => {
        const list = snapshot.docs.map((snapshotDoc) => ({
          id: snapshotDoc.id,
          ...snapshotDoc.data(),
        })) as Vehicle[]
        list.sort(
          (a, b) =>
            (b.createdAt?.toMillis?.() ?? 0) - (a.createdAt?.toMillis?.() ?? 0),
        )
        setVehicles(list)
        setVehiclesLoading(false)
      },
      () => {
        setError('Vehicles could not be loaded. Check Firestore rules.')
        setVehiclesLoading(false)
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

  const availableDrivers = useMemo(() => {
    return users.filter((user) => user.status === 'approved' && (user.approvedRole ?? user.requestedRole) === 'driver')
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
    if (user.status !== 'pending') {
      const decision = status === 'approved' ? 'approve' : 'reject'
      const confirmed = window.confirm(
        `Are you sure you want to ${decision} ${user.fullName}? This will replace the previous decision.`,
      )
      if (!confirmed) return
    }

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

  async function saveMockUser(e: React.FormEvent) {
    e.preventDefault()
    setIsSaving(true)
    setError('')
    try {
      await addDoc(collection(db, 'users'), {
        fullName: newMockUser.fullName,
        phoneNumber: newMockUser.phoneNumber,
        email: newMockUser.email,
        status: 'approved',
        requestedRole: newMockUser.role,
        approvedRole: newMockUser.role,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      })
      setIsAddingMockUser(false)
      setNewMockUser({ fullName: '', phoneNumber: '', email: '', role: 'driver' })
    } catch {
      setError('Failed to create mock user. Check firestore rules.')
    } finally {
      setIsSaving(false)
    }
  }

  async function removeUser(userId: string) {
    if (!window.confirm('Are you sure you want to permanently delete this user?')) return
    setError('')
    try {
      await deleteDoc(doc(db, 'users', userId))
    } catch {
      setError('Failed to delete user.')
    }
  }

  async function saveEditedUser(e: React.FormEvent) {
    e.preventDefault()
    if (!editingUser) return
    setIsSaving(true)
    setError('')
    try {
      await updateDoc(doc(db, 'users', editingUser.id), {
        fullName: editingUser.fullName,
        phone: editingUser.phone,
        email: editingUser.email,
        requestedRole: editingUser.requestedRole,
        updatedAt: serverTimestamp(),
      })
      setEditingUser(null)
    } catch {
      setError('Failed to update user.')
    } finally {
      setIsSaving(false)
    }
  }

  async function assignDriver(e: React.FormEvent) {
    e.preventDefault()
    if (!assigningDriverVehicle) return

    setIsSaving(true)
    setError('')
    try {
      const form = e.target as HTMLFormElement
      const driverId = (form.elements.namedItem('driverId') as HTMLSelectElement).value

      await updateDoc(doc(db, 'vehicles', assigningDriverVehicle.id), {
        assignedDriverId: driverId === 'unassigned' ? null : driverId,
        updatedAt: serverTimestamp(),
      })
      setAssigningDriverVehicle(null)
    } catch {
      setError('Failed to assign driver. Please try again.')
    } finally {
      setIsSaving(false)
    }
  }

  async function saveVehicle(e: React.FormEvent) {
    e.preventDefault()
    setIsSaving(true)
    setError('')
    try {
      await addDoc(collection(db, 'vehicles'), {
        plateNumber: newVehicle.plateNumber.toUpperCase(),
        displayName: newVehicle.displayName,
        type: newVehicle.type,
        capacity: Number(newVehicle.capacity),
        status: 'active',
        assignedDriverId: null,
        routeId: null,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      })
      setIsAddingVehicle(false)
      setNewVehicle({ plateNumber: '', displayName: '', type: 'van', capacity: 10 })
    } catch {
      setError('Failed to add the vehicle. Please try again.')
    } finally {
      setIsSaving(false)
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
          <button className={`nav-item ${currentTab === 'overview' || currentTab === 'people' ? 'active' : ''}`} onClick={() => { setCurrentTab('overview'); setSidebarOpen(false); }}>
            <LayoutDashboard size={19} />Overview
          </button>
          <button className={`nav-item ${currentTab === 'vehicles' ? 'active' : ''}`} onClick={() => { setCurrentTab('vehicles'); setSidebarOpen(false); }}>
            <BusFront size={19} />Vehicles
          </button>
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
          {(currentTab === 'overview' || currentTab === 'people') && (
            <>
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
                    <button className="primary-button small" onClick={() => setIsAddingMockUser(true)}>
                      <Plus size={16} /> Add Test User
                    </button>
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
                            <div className="row-actions">
                              {user.status === 'pending' && (
                                <>
                                  <button
                                    className="approve-button"
                                    disabled={updatingId === user.id}
                                    onClick={() => updateAccount(user, 'approved')}
                                    title="Approve"
                                  ><Check size={16} /></button>
                                  <button
                                    className="reject-button"
                                    disabled={updatingId === user.id}
                                    onClick={() => updateAccount(user, 'rejected')}
                                    title="Reject"
                                  ><X size={17} /></button>
                                </>
                              )}
                              {user.status === 'approved' && (
                                <button
                                  className="change-decision-button reject"
                                  disabled={updatingId === user.id}
                                  onClick={() => updateAccount(user, 'rejected')}
                                  title="Change to rejected"
                                >
                                  <X size={15} />
                                </button>
                              )}
                              {user.status === 'rejected' && (
                                <button
                                  className="change-decision-button approve"
                                  disabled={updatingId === user.id}
                                  onClick={() => updateAccount(user, 'approved')}
                                  title="Approve instead"
                                >
                                  <Check size={15} />
                                </button>
                              )}
                              <button
                                className="change-decision-button"
                                style={{ color: '#506872' }}
                                onClick={() => setEditingUser(user)}
                                title="Edit"
                              ><Pencil size={15} /></button>
                              <button
                                className="change-decision-button reject"
                                onClick={() => removeUser(user.id)}
                                title="Delete"
                              ><Trash2 size={15} /></button>
                            </div>
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
            </>
          )}

          {currentTab === 'vehicles' && (
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <span className="eyebrow blue">Fleet management</span>
                  <h2>Vehicles</h2>
                  <p>Manage the company transport fleet and assignments.</p>
                </div>
                <div className="toolbar">
                  <button className="primary-button small" onClick={() => setIsAddingVehicle(true)}>
                    <Plus size={16} /> Add Vehicle
                  </button>
                </div>
              </div>

              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Plate Number</th>
                      <th>Vehicle Details</th>
                      <th>Capacity</th>
                      <th>Driver</th>
                      <th>Status</th>
                      <th><span className="sr-only">Actions</span></th>
                    </tr>
                  </thead>
                  <tbody>
                    {vehicles.map((vehicle) => (
                      <tr key={vehicle.id}>
                        <td>
                          <div className="person-cell">
                            <div className="person-avatar"><BusFront size={16} /></div>
                            <div><strong>{vehicle.plateNumber}</strong></div>
                          </div>
                        </td>
                        <td>
                          <div className="contact-cell">
                            <strong>{vehicle.displayName}</strong>
                            <span>{capitalize(vehicle.type)}</span>
                          </div>
                        </td>
                        <td>{vehicle.capacity} seats</td>
                        <td>
                          {vehicle.assignedDriverId ? (
                            <strong>{availableDrivers.find((d) => d.id === vehicle.assignedDriverId)?.fullName || 'Unknown'}</strong>
                          ) : (
                            <span className="status-badge pending" style={{ width: 'max-content' }}><span />Unassigned</span>
                          )}
                        </td>
                        <td><StatusBadge status={vehicle.status as any} /></td>
                        <td>
                          <div className="row-actions">
                            <button className="change-decision-button approve" onClick={() => setAssigningDriverVehicle(vehicle)}>Assign Driver</button>
                            <button className="change-decision-button reject">Edit</button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {!vehiclesLoading && vehicles.length === 0 && (
                <div className="empty-state">
                  <BusFront size={32} />
                  <h3>No vehicles yet</h3>
                  <p>There are no vehicles added to the fleet database.</p>
                </div>
              )}
              {vehiclesLoading && <div className="loading-row"><RefreshCw className="spin" size={20} />Loading vehicles…</div>}
            </section>
          )}
        </div>

        {isAddingVehicle && (
          <div className="modal-backdrop" onClick={() => setIsAddingVehicle(false)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h3>Add New Vehicle</h3>
                <button className="icon-button" onClick={() => setIsAddingVehicle(false)}><X size={20} /></button>
              </div>
              <form onSubmit={saveVehicle} className="modal-form">
                <label>Plate Number</label>
                <input required placeholder="e.g. NB-1234" value={newVehicle.plateNumber} onChange={(e) => setNewVehicle({ ...newVehicle, plateNumber: e.target.value })} />
                
                <label>Display Name</label>
                <input required placeholder="e.g. Office Van 01" value={newVehicle.displayName} onChange={(e) => setNewVehicle({ ...newVehicle, displayName: e.target.value })} />
                
                <div className="input-row">
                  <div className="input-group">
                    <label>Type</label>
                    <select value={newVehicle.type} onChange={(e) => setNewVehicle({ ...newVehicle, type: e.target.value })}>
                      <option value="van">Van</option>
                      <option value="bus">Bus</option>
                      <option value="car">Car</option>
                    </select>
                  </div>
                  <div className="input-group">
                    <label>Capacity (Seats)</label>
                    <input required type="number" min="1" max="60" value={newVehicle.capacity} onChange={(e) => setNewVehicle({ ...newVehicle, capacity: Number(e.target.value) })} />
                  </div>
                </div>

                {error && <div className="alert table-alert" style={{ margin: 0 }}><XCircle size={18} />{error}</div>}

                <div className="modal-actions">
                  <button type="button" className="secondary-button" onClick={() => setIsAddingVehicle(false)}>Cancel</button>
                  <button type="submit" className="primary-button small" disabled={isSaving}>
                    {isSaving ? <RefreshCw className="spin" size={16} /> : <Check size={16} />}
                    {isSaving ? 'Saving...' : 'Save Vehicle'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {assigningDriverVehicle && (
          <div className="modal-backdrop" onClick={() => setAssigningDriverVehicle(null)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h3>Assign Driver</h3>
                <button className="icon-button" onClick={() => setAssigningDriverVehicle(null)}><X size={20} /></button>
              </div>
              <form onSubmit={assignDriver} className="modal-form">
                <p style={{ margin: 0, fontSize: '13px', color: '#506872' }}>
                  Assigning a driver to <strong>{assigningDriverVehicle.plateNumber}</strong> ({assigningDriverVehicle.displayName}).
                </p>
                
                <label>Select Driver</label>
                <select name="driverId" defaultValue={assigningDriverVehicle.assignedDriverId || 'unassigned'} required>
                  <option value="unassigned">-- Unassigned --</option>
                  {availableDrivers.map((driver) => (
                    <option key={driver.id} value={driver.id}>
                      {driver.fullName} ({driver.email})
                    </option>
                  ))}
                </select>

                {error && <div className="alert table-alert" style={{ margin: 0 }}><XCircle size={18} />{error}</div>}

                <div className="modal-actions">
                  <button type="button" className="secondary-button" onClick={() => setAssigningDriverVehicle(null)}>Cancel</button>
                  <button type="submit" className="primary-button small" disabled={isSaving}>
                    {isSaving ? <RefreshCw className="spin" size={16} /> : <Check size={16} />}
                    {isSaving ? 'Saving...' : 'Save Assignment'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {isAddingMockUser && (
          <div className="modal-backdrop" onClick={() => setIsAddingMockUser(false)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h3>Add Test User</h3>
                <button className="icon-button" onClick={() => setIsAddingMockUser(false)}><X size={20} /></button>
              </div>
              <form onSubmit={saveMockUser} className="modal-form">
                <p style={{ margin: 0, fontSize: '12px', color: '#617780' }}>
                  This creates a mock user instantly approved as a passenger or driver.
                </p>
                <label>Full Name</label>
                <input required placeholder="e.g. John Doe" value={newMockUser.fullName} onChange={(e) => setNewMockUser({ ...newMockUser, fullName: e.target.value })} />
                
                <div className="input-row">
                  <div className="input-group">
                    <label>Phone Number</label>
                    <input required type="tel" placeholder="e.g. +94771234567" value={newMockUser.phoneNumber} onChange={(e) => setNewMockUser({ ...newMockUser, phoneNumber: e.target.value })} />
                  </div>
                  <div className="input-group">
                    <label>Role</label>
                    <select value={newMockUser.role} onChange={(e) => setNewMockUser({ ...newMockUser, role: e.target.value })}>
                      <option value="driver">Driver</option>
                      <option value="passenger">Passenger</option>
                    </select>
                  </div>
                </div>

                <label>Email (Optional)</label>
                <input type="email" placeholder="e.g. john@example.com" value={newMockUser.email} onChange={(e) => setNewMockUser({ ...newMockUser, email: e.target.value })} />

                {error && <div className="alert table-alert" style={{ margin: 0 }}><XCircle size={18} />{error}</div>}

                <div className="modal-actions">
                  <button type="button" className="secondary-button" onClick={() => setIsAddingMockUser(false)}>Cancel</button>
                  <button type="submit" className="primary-button small" disabled={isSaving}>
                    {isSaving ? <RefreshCw className="spin" size={16} /> : <Check size={16} />}
                    {isSaving ? 'Creating...' : 'Create User'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {editingUser && (
          <div className="modal-backdrop" onClick={() => setEditingUser(null)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h3>Edit User</h3>
                <button className="icon-button" onClick={() => setEditingUser(null)}><X size={20} /></button>
              </div>
              <form onSubmit={saveEditedUser} className="modal-form">
                <label>Full Name</label>
                <input required placeholder="e.g. John Doe" value={editingUser.fullName} onChange={(e) => setEditingUser({ ...editingUser, fullName: e.target.value })} />
                
                <div className="input-row">
                  <div className="input-group">
                    <label>Phone Number</label>
                    <input required type="tel" placeholder="e.g. +94771234567" value={editingUser.phone} onChange={(e) => setEditingUser({ ...editingUser, phone: e.target.value })} />
                  </div>
                  <div className="input-group">
                    <label>Role</label>
                    <select value={editingUser.requestedRole} onChange={(e) => setEditingUser({ ...editingUser, requestedRole: e.target.value as 'passenger' | 'driver' })}>
                      <option value="driver">Driver</option>
                      <option value="passenger">Passenger</option>
                    </select>
                  </div>
                </div>

                <label>Email (Optional)</label>
                <input type="email" placeholder="e.g. john@example.com" value={editingUser.email} onChange={(e) => setEditingUser({ ...editingUser, email: e.target.value })} />

                {error && <div className="alert table-alert" style={{ margin: 0 }}><XCircle size={18} />{error}</div>}

                <div className="modal-actions">
                  <button type="button" className="secondary-button" onClick={() => setEditingUser(null)}>Cancel</button>
                  <button type="submit" className="primary-button small" disabled={isSaving}>
                    {isSaving ? <RefreshCw className="spin" size={16} /> : <Check size={16} />}
                    {isSaving ? 'Saving...' : 'Save Changes'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
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

function initials(value?: string | null) {
  if (!value) return 'A'
  return value.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join('').toUpperCase() || 'A'
}

function capitalize(value?: string | null) {
  if (!value) return ''
  return value.charAt(0).toUpperCase() + value.slice(1)
}

function formatDate(value?: Timestamp | null) {
  if (!value?.toDate) return '—'
  return new Intl.DateTimeFormat('en-LK', { day: '2-digit', month: 'short', year: 'numeric' }).format(value.toDate())
}

export default App
