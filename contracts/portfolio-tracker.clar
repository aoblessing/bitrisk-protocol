;; BitRisk Protocol - Portfolio Tracker Contract (v1.0)
;; Basic position tracking across DeFi protocols

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u501))
(define-constant ERR-POSITION-NOT-FOUND (err u502))
(define-constant ERR-INVALID-PROTOCOL (err u503))
(define-constant ERR-INVALID-AMOUNT (err u505))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Supported protocols
(define-constant PROTOCOL-ARKADIKO "arkadiko")
(define-constant PROTOCOL-ALEX "alex")
(define-constant PROTOCOL-ZEST "zest")
(define-constant PROTOCOL-STACKSWAP "stackswap")

;; Position types
(define-constant POSITION-TYPE-LENDING "lending")
(define-constant POSITION-TYPE-BORROWING "borrowing")
(define-constant POSITION-TYPE-LP "liquidity")

;; Position data structure
(define-map user-positions
  { user: principal, position-id: uint }
  {
    protocol: (string-ascii 20),        ;; Protocol name
    position-type: (string-ascii 20),   ;; Position type
    collateral-asset: (string-ascii 10), ;; Collateral token
    debt-asset: (string-ascii 10),      ;; Debt token (if applicable)
    collateral-amount: uint,            ;; Amount of collateral
    debt-amount: uint,                  ;; Amount of debt
    created-at: uint,                   ;; Block height when created
    is-active: bool                     ;; Position status
  }
)

;; User position counters
(define-map user-position-count
  { user: principal }
  { count: uint }
)

;; Add a new position
(define-public (add-position
  (protocol (string-ascii 20))
  (position-type (string-ascii 20))
  (collateral-asset (string-ascii 10))
  (debt-asset (string-ascii 10))
  (collateral-amount uint)
  (debt-amount uint)
)
  (let
    (
      (user tx-sender)
      (current-count (default-to u0 (get count (map-get? user-position-count { user: user }))))
      (new-position-id (+ current-count u1))
    )
    ;; Validate inputs
    (asserts! (> collateral-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-valid-protocol protocol) ERR-INVALID-PROTOCOL)
    
    ;; Create the position
    (map-set user-positions
      { user: user, position-id: new-position-id }
      {
        protocol: protocol,
        position-type: position-type,
        collateral-asset: collateral-asset,
        debt-asset: debt-asset,
        collateral-amount: collateral-amount,
        debt-amount: debt-amount,
        created-at: stacks-block-height,
        is-active: true
      }
    )
    
    ;; Update position counter
    (map-set user-position-count
      { user: user }
      { count: new-position-id }
    )
    
    (ok new-position-id)
  )
)

;; Update an existing position
(define-public (update-position
  (position-id uint)
  (collateral-amount uint)
  (debt-amount uint)
)
  (let
    (
      (user tx-sender)
      (existing-position (unwrap! (map-get? user-positions { user: user, position-id: position-id }) ERR-POSITION-NOT-FOUND))
    )
    ;; Validate user owns this position and it's active
    (asserts! (get is-active existing-position) ERR-POSITION-NOT-FOUND)
    (asserts! (> collateral-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Update the position
    (map-set user-positions
      { user: user, position-id: position-id }
      (merge existing-position {
        collateral-amount: collateral-amount,
        debt-amount: debt-amount
      })
    )
    
    (ok true)
  )
)

;; Get a specific position
(define-read-only (get-position (user principal) (position-id uint))
  (map-get? user-positions { user: user, position-id: position-id })
)

;; Get user position count
(define-read-only (get-user-position-count (user principal))
  (default-to u0 (get count (map-get? user-position-count { user: user })))
)

;; Helper function to validate protocol
(define-private (is-valid-protocol (protocol (string-ascii 20)))
  (or 
    (is-eq protocol PROTOCOL-ARKADIKO)
    (or 
      (is-eq protocol PROTOCOL-ALEX)
      (or 
        (is-eq protocol PROTOCOL-ZEST)
        (is-eq protocol PROTOCOL-STACKSWAP)
      )
    )
  )
)
