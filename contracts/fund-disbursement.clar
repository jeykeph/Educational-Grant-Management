;; Fund Disbursement Contract
;; Manages payments for approved projects

(define-data-var next-grant-id uint u0)

(define-map grants
  { grant-id: uint }
  {
    funder-id: uint,
    applicant-id: uint,
    amount: uint,
    description: (string-ascii 500),
    status: (string-ascii 20),
    created-at: uint,
    disbursed-at: (optional uint),
    funder-principal: principal
  }
)

(define-map disbursements
  { grant-id: uint, disbursement-id: uint }
  {
    amount: uint,
    timestamp: uint,
    milestone: (string-ascii 100),
    status: (string-ascii 20)
  }
)

(define-data-var next-disbursement-id uint u0)

(define-read-only (get-grant (grant-id uint))
  (map-get? grants { grant-id: grant-id })
)

(define-read-only (get-disbursement (grant-id uint) (disbursement-id uint))
  (map-get? disbursements { grant-id: grant-id, disbursement-id: disbursement-id })
)

(define-read-only (get-next-grant-id)
  (var-get next-grant-id)
)

(define-read-only (get-next-disbursement-id)
  (var-get next-disbursement-id)
)

;; Create a new grant
(define-public (create-grant
    (funder-id uint)
    (applicant-id uint)
    (amount uint)
    (description (string-ascii 500))
  )
  (let ((grant-id (var-get next-grant-id)))
    ;; Here we would typically verify that tx-sender is authorized for this funder
    ;; and that the applicant is verified, but we've simplified for this example

    (map-set grants
      { grant-id: grant-id }
      {
        funder-id: funder-id,
        applicant-id: applicant-id,
        amount: amount,
        description: description,
        status: "approved",
        created-at: block-height,
        disbursed-at: none,
        funder-principal: tx-sender
      }
    )
    (var-set next-grant-id (+ grant-id u1))
    (ok grant-id)
  )
)

;; Create a disbursement for a grant
(define-public (create-disbursement
    (grant-id uint)
    (amount uint)
    (milestone (string-ascii 100))
  )
  (let (
      (grant-data (unwrap! (get-grant grant-id) (err u1)))
      (disbursement-id (var-get next-disbursement-id))
    )
    ;; Verify sender is the funder who created this grant
    (asserts! (is-eq tx-sender (get funder-principal grant-data)) (err u2))

    (map-set disbursements
      { grant-id: grant-id, disbursement-id: disbursement-id }
      {
        amount: amount,
        timestamp: block-height,
        milestone: milestone,
        status: "pending"
      }
    )
    (var-set next-disbursement-id (+ disbursement-id u1))
    (ok disbursement-id)
  )
)

;; Mark a disbursement as completed
(define-public (complete-disbursement (grant-id uint) (disbursement-id uint))
  (let (
      (grant-data (unwrap! (get-grant grant-id) (err u1)))
      (disbursement-data (unwrap! (get-disbursement grant-id disbursement-id) (err u2)))
    )
    ;; Verify sender is the funder who created this grant
    (asserts! (is-eq tx-sender (get funder-principal grant-data)) (err u3))

    (map-set disbursements
      { grant-id: grant-id, disbursement-id: disbursement-id }
      (merge disbursement-data { status: "completed" })
    )

    ;; If this is the last disbursement, mark the grant as fully disbursed
    ;; In a real contract, you'd check if all disbursements are completed
    (map-set grants
      { grant-id: grant-id }
      (merge grant-data {
        status: "disbursed",
        disbursed-at: (some block-height)
      })
    )

    (ok true)
  )
)
