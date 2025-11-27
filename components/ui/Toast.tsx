'use client'

import { createContext, useContext, useState, ReactNode } from 'react'
import { X, CheckCircle, XCircle, Info } from 'lucide-react'
import styles from './Toast.module.css'

type ToastType = 'success' | 'error' | 'info'

interface Toast {
    id: string
    type: ToastType
    title: string
    message?: string
}

interface ToastContextType {
    showToast: (type: ToastType, title: string, message?: string) => void
}

const ToastContext = createContext<ToastContextType | undefined>(undefined)

export function ToastProvider({ children }: { children: ReactNode }) {
    const [toasts, setToasts] = useState<Toast[]>([])

    const showToast = (type: ToastType, title: string, message?: string) => {
        const id = Math.random().toString(36).substr(2, 9)
        const newToast = { id, type, title, message }

        setToasts(prev => [...prev, newToast])

        setTimeout(() => {
            setToasts(prev => prev.filter(t => t.id !== id))
        }, 5000)
    }

    const removeToast = (id: string) => {
        setToasts(prev => prev.filter(t => t.id !== id))
    }

    const getIcon = (type: ToastType) => {
        switch (type) {
            case 'success':
                return <CheckCircle size={20} color="#22c55e" />
            case 'error':
                return <XCircle size={20} color="#ef4444" />
            case 'info':
                return <Info size={20} color="#3b82f6" />
        }
    }

    return (
        <ToastContext.Provider value={{ showToast }}>
            {children}
            <div className={styles.toastContainer}>
                {toasts.map(toast => (
                    <div key={toast.id} className={`${styles.toast} ${styles[toast.type]}`}>
                        <div className={styles.toastIcon}>
                            {getIcon(toast.type)}
                        </div>
                        <div className={styles.toastContent}>
                            <div className={styles.toastTitle}>{toast.title}</div>
                            {toast.message && <div className={styles.toastMessage}>{toast.message}</div>}
                        </div>
                        <button className={styles.toastClose} onClick={() => removeToast(toast.id)}>
                            <X size={16} />
                        </button>
                    </div>
                ))}
            </div>
        </ToastContext.Provider>
    )
}

export function useToast() {
    const context = useContext(ToastContext)
    if (!context) {
        throw new Error('useToast must be used within ToastProvider')
    }
    return context
}
