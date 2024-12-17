;; NFTForge Protocol
;; A dynamic NFT system with scarcity mechanisms and upgrade capabilities

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-id-not-found (err u102))
(define-constant err-insufficient-tokens (err u103))
(define-constant err-mint-limit-reached (err u104))
(define-constant err-invalid-sender (err u105))
(define-constant err-not-authorized (err u106))

;; Data Variables
(define-data-var total-supply uint u0)
(define-data-var mint-price uint u100000000) ;; 100 STX
(define-data-var max-supply uint u1000)
(define-data-var demand-factor uint u100) ;; Base 100 for percentage calculations
(define-data-var contract-paused bool false)

;; NFT Collection Data Maps
(define-map tokens 
    {token-id: uint} 
    {owner: principal, level: uint, metadata-uri: (string-ascii 256)})

(define-map token-count principal uint)

;; Access Control Map
(define-map authorized-operators principal bool)

;; Public Functions

;; Mint new NFT
(define-public (mint (metadata-uri (string-ascii 256)))
    (let 
        (
            (token-id (var-get total-supply))
            (current-balance (default-to u0 (map-get? token-count tx-sender)))
        )
        (asserts! (not (var-get contract-paused)) err-not-authorized)
        (asserts! (< token-id (var-get max-supply)) err-mint-limit-reached)
        (try! (stx-transfer? (var-get mint-price) tx-sender contract-owner))
        
        ;; Dynamic scarcity adjustment
        (if (> token-id u500)
            (var-set demand-factor (- (var-get demand-factor) u10))
            true
        )
        
        ;; Create token
        (map-set tokens 
            {token-id: token-id}
            {owner: tx-sender, 
             level: u1,
             metadata-uri: metadata-uri})
             
        ;; Update user balance
        (map-set token-count 
            tx-sender 
            (+ current-balance u1))
            
        ;; Increment total supply
        (var-set total-supply (+ token-id u1))
        (ok token-id)
    )
)

;; Upgrade NFT by burning others
(define-public (upgrade-nft (token-id uint) (burn-token-id uint))
    (let
        (
            (token (unwrap! (map-get? tokens {token-id: token-id}) err-token-id-not-found))
            (burn-token (unwrap! (map-get? tokens {token-id: burn-token-id}) err-token-id-not-found))
        )
        (asserts! (not (var-get contract-paused)) err-not-authorized)
        ;; Check ownership
        (asserts! (is-eq (get owner token) tx-sender) err-not-token-owner)
        (asserts! (is-eq (get owner burn-token) tx-sender) err-not-token-owner)
        
        ;; Burn token and upgrade target
        (map-delete tokens {token-id: burn-token-id})
        (map-set tokens
            {token-id: token-id}
            {owner: tx-sender,
             level: (+ (get level token) u1),
             metadata-uri: (get metadata-uri token)})
             
        ;; Update user balance
        (map-set token-count
            tx-sender
            (- (default-to u0 (map-get? token-count tx-sender)) u1))
            
        (ok true)
    )
)

;; Transfer NFT
(define-public (transfer (token-id uint) (recipient principal))
    (let
        (
            (token (unwrap! (map-get? tokens {token-id: token-id}) err-token-id-not-found))
        )
        (asserts! (not (var-get contract-paused)) err-not-authorized)
        (asserts! (is-eq (get owner token) tx-sender) err-not-token-owner)
        
        ;; Update token owner
        (map-set tokens
            {token-id: token-id}
            {owner: recipient,
             level: (get level token),
             metadata-uri: (get metadata-uri token)})
             
        ;; Update balances
        (map-set token-count
            tx-sender
            (- (default-to u0 (map-get? token-count tx-sender)) u1))
        (map-set token-count
            recipient
            (+ (default-to u0 (map-get? token-count recipient)) u1))
            
        (ok true)
    )
)

;; Read-Only Functions

(define-read-only (get-token-owner (token-id uint))
    (ok (get owner (unwrap! (map-get? tokens {token-id: token-id}) err-token-id-not-found)))
)

(define-read-only (get-token-level (token-id uint))
    (ok (get level (unwrap! (map-get? tokens {token-id: token-id}) err-token-id-not-found)))
)

(define-read-only (get-token-uri (token-id uint))
    (ok (get metadata-uri (unwrap! (map-get? tokens {token-id: token-id}) err-token-id-not-found)))
)

(define-read-only (get-balance (account principal))
    (ok (default-to u0 (map-get? token-count account)))
)

(define-read-only (get-total-supply)
    (ok (var-get total-supply))
)

(define-read-only (get-mint-price)
    (ok (var-get mint-price))
)

(define-read-only (get-demand-factor)
    (ok (var-get demand-factor))
)

;; Contract Management Functions

(define-public (set-mint-price (new-price uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set mint-price new-price)
        (ok true)
    )
)

(define-public (set-max-supply (new-max uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set max-supply new-max)
        (ok true)
    )
)

(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set contract-paused (not (var-get contract-paused))))
    )
)

(define-public (set-operator (operator principal) (authorized bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set authorized-operators operator authorized))
    )
)