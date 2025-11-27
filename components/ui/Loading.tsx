import styles from './Loading.module.css'

interface LoadingProps {
    size?: 'small' | 'large'
    text?: string
    fullScreen?: boolean
}

export function Loading({ size = 'small', text, fullScreen = false }: LoadingProps) {
    const content = (
        <div className={styles.loadingContainer}>
            <div className={`${styles.spinner} ${size === 'large' ? styles.large : ''}`} />
            {text && <p className={styles.loadingText}>{text}</p>}
        </div>
    )

    if (fullScreen) {
        return (
            <div style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                minHeight: '100vh'
            }}>
                {content}
            </div>
        )
    }

    return content
}

export function Spinner({ size = 'small' }: { size?: 'small' | 'large' }) {
    return <div className={`${styles.spinner} ${size === 'large' ? styles.large : ''}`} />
}
