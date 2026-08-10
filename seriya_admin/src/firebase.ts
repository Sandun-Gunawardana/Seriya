import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

// Firebase web configuration identifies the public Firebase project. Access is
// protected by Firebase Authentication and Firestore security rules, not by
// hiding these browser-visible values.
const firebaseConfig = {
  apiKey: 'AIzaSyAZlOH6VqSQ3JgD4Os5JD56DLnwd8a610Y',
  authDomain: 'seriya-9ccfd.firebaseapp.com',
  projectId: 'seriya-9ccfd',
  storageBucket: 'seriya-9ccfd.firebasestorage.app',
  messagingSenderId: '1067325308812',
  appId: '1:1067325308812:web:0048d7f3d8ba4d0524e0a9',
  measurementId: 'G-L6SNPH3JFY',
}

const firebaseApp = initializeApp(firebaseConfig)

export const auth = getAuth(firebaseApp)
export const db = getFirestore(firebaseApp)
