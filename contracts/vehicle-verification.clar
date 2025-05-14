;; Vehicle Verification Contract
;; Validates connected cars and maintains a registry of verified vehicles

(define-data-var admin principal tx-sender)

;; Data structure for vehicle information
(define-map vehicles
  { vehicle-id: (string-ascii 17) }  ;; VIN (Vehicle Identification Number)
  {
    owner: principal,
    make: (string-ascii 50),
    model: (string-ascii 50),
    year: uint,
    verified: bool
  }
)

;; Public function to register a new vehicle
(define-public (register-vehicle (vehicle-id (string-ascii 17)) (make (string-ascii 50)) (model (string-ascii 50)) (year uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (not (is-some (map-get? vehicles { vehicle-id: vehicle-id }))) (err u100))
    (ok (map-set vehicles
      { vehicle-id: vehicle-id }
      {
        owner: tx-sender,
        make: make,
        model: model,
        year: year,
        verified: false
      }
    ))
  )
)

;; Public function to verify a vehicle
(define-public (verify-vehicle (vehicle-id (string-ascii 17)))
  (let ((vehicle-data (unwrap! (map-get? vehicles { vehicle-id: vehicle-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set vehicles
        { vehicle-id: vehicle-id }
        (merge vehicle-data { verified: true })
      ))
    )
  )
)

;; Public function to transfer vehicle ownership
(define-public (transfer-vehicle (vehicle-id (string-ascii 17)) (new-owner principal))
  (let ((vehicle-data (unwrap! (map-get? vehicles { vehicle-id: vehicle-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (get owner vehicle-data)) (err u403))
      (ok (map-set vehicles
        { vehicle-id: vehicle-id }
        (merge vehicle-data { owner: new-owner })
      ))
    )
  )
)

;; Read-only function to check if a vehicle is verified
(define-read-only (is-vehicle-verified (vehicle-id (string-ascii 17)))
  (match (map-get? vehicles { vehicle-id: vehicle-id })
    vehicle-data (ok (get verified vehicle-data))
    (err u404)
  )
)

;; Read-only function to get vehicle details
(define-read-only (get-vehicle-details (vehicle-id (string-ascii 17)))
  (map-get? vehicles { vehicle-id: vehicle-id })
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
