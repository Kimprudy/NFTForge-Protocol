;; NFTForge Protocol with Dynamic Minting Algorithm
;; Implements real-time market factor based minting controls

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-id-not-found (err u102))
(define-constant err-insufficient-tokens (err u103))
(define-constant err-mint-limit-reached (err u104))
(define-constant err-invalid-sender (err u105))
(define-constant err-not-authorized (err u106))
(define-constant err-market-cooldown (err u107))
(define-constant err-below-floor-price (err u108))
(define-constant err-invalid-token-id (err u109))
(define-constant err-invalid-uri (err u110))
(define-constant err-invalid-parameter (err u111))

;; Data Variables
(define-data-var total-supply uint u0)
(define-data-var mint-price uint u100000000) ;; 100 STX
(define-data-var max-supply uint u1000)
(define-data-var contract-paused bool false)

;; Market Metrics
(define-data-var floor-price uint u100000000) ;; 100 STX
(define-data-var total-volume uint u0)
(define-data-var active-holders uint u0)
(define-data-var last-mint-block uint u0)
(define-data-var mint-cooldown uint u100) ;; blocks between mints
(define-data-var market-multiplier uint u100) ;; base 100 for percentage

;; Input Validation Functions
(define-private (is-valid-token-id (token-id uint))
    (and 
        (<= token-id (var-get total-supply))
        (is-some (map-get? tokens {token-id: token-id}))
    )
)

(define-private (is-valid-uri (uri (string-ascii 256)))
    (and
        (not (is-eq uri ""))
        (<= (len uri) u256)
    )
)

(define-private (is-valid-parameter (value uint))
    (> value u0)
)

;; Dynamic Minting Controls
(define-map holder-activity 
    principal 
    {last-transfer: uint, transfer-count: uint})

(define-map price-points
    uint  ;; block height
    {price: uint, volume: uint})

;; NFT Collection Data Maps
(define-map tokens 
    {token-id: uint} 
    {owner: principal, level: uint, metadata-uri: (string-ascii 256)})

(define-map token-count principal uint)

;; Market Analysis Functions

(define-private (calculate-market-multiplier)
    (let
        (
            (holder-factor (/ (* (var-get active-holders) u100) (var-get max-supply)))
            (volume-factor (/ (var-get total-volume) (var-get floor-price)))
            (base-multiplier u100)
        )
        (+ base-multiplier (+ holder-factor (/ volume-factor u100)))
    )
)

(define-private (update-market-metrics (price uint))
    (begin
        (if (< price (var-get floor-price))
            (var-set floor-price price)
            true
        )
        (var-set total-volume (+ (var-get total-volume) price))
        (var-set market-multiplier (calculate-market-multiplier))
        (map-set price-points
            block-height
            {price: price, volume: (var-get total-volume)})
    )
)

(define-private (update-holder-activity (holder principal))
    (let
        (
            (current-activity (default-to 
                {last-transfer: u0, transfer-count: u0} 
                (map-get? holder-activity holder)))
        )
        (map-set holder-activity
            holder
            {
                last-transfer: block-height,
                transfer-count: (+ (get transfer-count current-activity) u1)
            }
        )
    )
)

;; Enhanced Minting Function
(define-public (mint (metadata-uri (string-ascii 256)))
    (let 
        (
            (token-id (var-get total-supply))
            (current-balance (default-to u0 (map-get? token-count tx-sender)))
            (dynamic-mint-limit (/ (* (var-get max-supply) (var-get market-multiplier)) u100))
        )
        ;; Input validation
        (asserts! (is-valid-uri metadata-uri) err-invalid-uri)
        
        ;; Contract state validation
        (asserts! (not (var-get contract-paused)) err-not-authorized)
        (asserts! (< token-id dynamic-mint-limit) err-mint-limit-reached)
        (asserts! (>= (- block-height (var-get last-mint-block)) (var-get mint-cooldown)) err-market-cooldown)
        
        ;; Process minting payment
        (try! (stx-transfer? (var-get mint-price) tx-sender contract-owner))
        
        ;; Update market metrics
        (update-market-metrics (var-get mint-price))
        
        ;; Create token with validated data
        (map-set tokens 
            {token-id: token-id}
            {owner: tx-sender, 
             level: u1,
             metadata-uri: metadata-uri})
             
        ;; Update holder metrics
        (if (is-eq current-balance u0)
            (var-set active-holders (+ (var-get active-holders) u1))
            true
        )
        
        ;; Update user balance
        (map-set token-count 
            tx-sender 
            (+ current-balance u1))
            
        ;; Update mint timing
        (var-set last-mint-block block-height)
        
        ;; Increment total supply
        (var-set total-supply (+ token-id u1))
        (ok token-id)
    )
)

;; Enhanced Transfer Function
(define-public (transfer (token-id uint) (recipient principal))
    (let
        (
            (token (unwrap! (map-get? tokens {token-id: token-id}) err-token-id-not-found))
            (sender-balance (default-to u0 (map-get? token-count tx-sender)))
            (recipient-balance (default-to u0 (map-get? token-count recipient)))
        )
        ;; Input validation
        (asserts! (is-valid-token-id token-id) err-invalid-token-id)
        
        ;; Contract state validation
        (asserts! (not (var-get contract-paused)) err-not-authorized)
        (asserts! (is-eq (get owner token) tx-sender) err-not-token-owner)
        
        ;; Update holder metrics
        (if (is-eq recipient-balance u0)
            (var-set active-holders (+ (var-get active-holders) u1))
            true
        )
        (if (is-eq (- sender-balance u1) u0)
            (var-set active-holders (- (var-get active-holders) u1))
            true
        )
        
        ;; Update token owner with validated token-id
        (map-set tokens
            {token-id: token-id}
            {owner: recipient,
             level: (get level token),
             metadata-uri: (get metadata-uri token)})
             
        ;; Update balances
        (map-set token-count tx-sender (- sender-balance u1))
        (map-set token-count recipient (+ recipient-balance u1))
        
        ;; Update holder activity
        (update-holder-activity tx-sender)
        (update-holder-activity recipient)
            
        (ok true)
    )
)

;; Market Metric Getters
(define-read-only (get-market-metrics)
    (ok {
        floor-price: (var-get floor-price),
        total-volume: (var-get total-volume),
        active-holders: (var-get active-holders),
        market-multiplier: (var-get market-multiplier),
        dynamic-mint-limit: (/ (* (var-get max-supply) (var-get market-multiplier)) u100)
    })
)

(define-read-only (get-holder-activity (holder principal))
    (ok (default-to 
        {last-transfer: u0, transfer-count: u0}
        (map-get? holder-activity holder)))
)

;; Enhanced Management Functions
(define-public (set-mint-cooldown (new-cooldown uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-parameter new-cooldown) err-invalid-parameter)
        (var-set mint-cooldown new-cooldown)
        (ok true)
    )
)

(define-public (set-floor-price (new-floor-price uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-parameter new-floor-price) err-invalid-parameter)
        (var-set floor-price new-floor-price)
        (ok true)
    )
)