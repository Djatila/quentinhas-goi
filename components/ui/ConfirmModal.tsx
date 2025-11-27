'use client'

import { AlertTriangle } from 'lucide-react'
import { Button } from './Button'
import styles from './ConfirmModal.module.css'

interface ConfirmModalProps {
    isOpen: boolean
    title: string
    message: string
    onConfirm: () => void
    onCancel: () => void
    confirmText?: string
    cancelText?: string
}

export function ConfirmModal({
    isOpen,
    title,
    message,
    onConfirm,
    onCancel,
    confirmText = 'Confirmar',
    cancelText = 'Cancelar'
}: ConfirmModalProps) {
    if (!isOpen) return null

    return (
        <div className={styles.modal} onClick={onCancel}>
            <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
                <div className={styles.modalHeader}>
                    <div className={styles.modalIcon}>
                        <AlertTriangle size={24} />
                    </div>
                    <h3 className={styles.modalTitle}>{title}</h3>
                </div>
                <p className={styles.modalMessage}>{message}</p>
                <div className={styles.modalActions}>
                    <Button variant="secondary" onClick={onCancel}>
                        {cancelText}
                    </Button>
                    <Button variant="destructive" onClick={onConfirm}>
                        {confirmText}
                    </Button>
                </div>
            </div>
        </div>
    )
}
