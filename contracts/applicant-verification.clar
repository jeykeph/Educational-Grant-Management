;; Applicant Verification Contract
;; Validates eligibility of educational institutions

(define-data-var next-applicant-id uint u0)

(define-map applicants
  { applicant-id: uint }
  {
    name: (string-ascii 100),
    institution-type: (string-ascii 50),
    location: (string-ascii 100),
    contact-info: (string-ascii 100),
    verification-status: (string-ascii 20),
    verified-by: (optional principal),
    applicant-address: principal,
    created-at: uint
  }
)

(define-read-only (get-applicant (applicant-id uint))
  (map-get? applicants { applicant-id: applicant-id })
)

(define-read-only (get-next-applicant-id)
  (var-get next-applicant-id)
)

(define-public (register-applicant
    (name (string-ascii 100))
    (institution-type (string-ascii 50))
    (location (string-ascii 100))
    (contact-info (string-ascii 100))
  )
  (let ((applicant-id (var-get next-applicant-id)))
    (map-set applicants
      { applicant-id: applicant-id }
      {
        name: name,
        institution-type: institution-type,
        location: location,
        contact-info: contact-info,
        verification-status: "pending",
        verified-by: none,
        applicant-address: tx-sender,
        created-at: block-height
      }
    )
    (var-set next-applicant-id (+ applicant-id u1))
    (ok applicant-id)
  )
)

(define-constant VERIFIER_ROLE "verifier")

;; Update to include a check against some authorization contract or similar
(define-private (is-verifier (address principal))
  true
)

(define-public (verify-applicant (applicant-id uint) (status (string-ascii 20)))
  (let ((applicant-data (unwrap! (get-applicant applicant-id) (err u1))))
    (asserts! (is-verifier tx-sender) (err u403))
    (asserts! (or (is-eq status "approved") (is-eq status "rejected")) (err u2))

    (map-set applicants
      { applicant-id: applicant-id }
      (merge applicant-data {
        verification-status: status,
        verified-by: (some tx-sender)
      })
    )
    (ok true)
  )
)

(define-public (update-applicant-info
    (applicant-id uint)
    (name (string-ascii 100))
    (institution-type (string-ascii 50))
    (location (string-ascii 100))
    (contact-info (string-ascii 100))
  )
  (let ((applicant-data (unwrap! (get-applicant applicant-id) (err u1))))
    (asserts! (is-eq tx-sender (get applicant-address applicant-data)) (err u2))
    (map-set applicants
      { applicant-id: applicant-id }
      (merge applicant-data {
        name: name,
        institution-type: institution-type,
        location: location,
        contact-info: contact-info
      })
    )
    (ok true)
  )
)
