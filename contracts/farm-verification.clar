;; Farm Verification Contract
;; Validates and manages agricultural operations

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-verified (err u102))
(define-constant err-invalid-farm (err u103))

;; Farm data structure
(define-map farms
  { farm-id: uint }
  {
    owner: principal,
    location: (string-ascii 100),
    size-acres: uint,
    verified: bool,
    verification-date: uint,
    certifier: principal
  }
)

;; Farm counter
(define-data-var farm-counter uint u0)

;; Authorized certifiers
(define-map authorized-certifiers principal bool)

;; Register a new farm
(define-public (register-farm (location (string-ascii 100)) (size-acres uint))
  (let
    (
      (farm-id (+ (var-get farm-counter) u1))
    )
    (map-set farms
      { farm-id: farm-id }
      {
        owner: tx-sender,
        location: location,
        size-acres: size-acres,
        verified: false,
        verification-date: u0,
        certifier: tx-sender
      }
    )
    (var-set farm-counter farm-id)
    (ok farm-id)
  )
)

;; Add authorized certifier (owner only)
(define-public (add-certifier (certifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-certifiers certifier true)
    (ok true)
  )
)

;; Verify a farm (authorized certifiers only)
(define-public (verify-farm (farm-id uint))
  (let
    (
      (farm-data (unwrap! (map-get? farms { farm-id: farm-id }) err-not-found))
      (is-authorized (default-to false (map-get? authorized-certifiers tx-sender)))
    )
    (asserts! is-authorized err-owner-only)
    (asserts! (not (get verified farm-data)) err-already-verified)
    (map-set farms
      { farm-id: farm-id }
      (merge farm-data {
        verified: true,
        verification-date: block-height,
        certifier: tx-sender
      })
    )
    (ok true)
  )
)

;; Get farm details
(define-read-only (get-farm (farm-id uint))
  (map-get? farms { farm-id: farm-id })
)

;; Check if farm is verified
(define-read-only (is-farm-verified (farm-id uint))
  (match (map-get? farms { farm-id: farm-id })
    farm-data (get verified farm-data)
    false
  )
)

;; Get total farms count
(define-read-only (get-farm-count)
  (var-get farm-counter)
)
