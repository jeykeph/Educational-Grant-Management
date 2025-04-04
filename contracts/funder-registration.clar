;; Funder Registration Contract
;; Records details of grant-providing organizations

(define-data-var next-funder-id uint u0)

(define-map funders
  { funder-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    website: (string-ascii 100),
    authorized-by: principal,
    active: bool,
    created-at: uint
  }
)

(define-read-only (get-funder (funder-id uint))
  (map-get? funders { funder-id: funder-id })
)

(define-read-only (get-next-funder-id)
  (var-get next-funder-id)
)

(define-public (register-funder
    (name (string-ascii 100))
    (description (string-ascii 500))
    (website (string-ascii 100))
  )
  (let ((funder-id (var-get next-funder-id)))
    (map-set funders
      { funder-id: funder-id }
      {
        name: name,
        description: description,
        website: website,
        authorized-by: tx-sender,
        active: true,
        created-at: block-height
      }
    )
    (var-set next-funder-id (+ funder-id u1))
    (ok funder-id)
  )
)

(define-public (update-funder
    (funder-id uint)
    (name (string-ascii 100))
    (description (string-ascii 500))
    (website (string-ascii 100))
  )
  (let ((funder-data (unwrap! (get-funder funder-id) (err u1))))
    (asserts! (is-eq tx-sender (get authorized-by funder-data)) (err u2))
    (map-set funders
      { funder-id: funder-id }
      (merge funder-data {
        name: name,
        description: description,
        website: website
      })
    )
    (ok true)
  )
)

(define-public (deactivate-funder (funder-id uint))
  (let ((funder-data (unwrap! (get-funder funder-id) (err u1))))
    (asserts! (is-eq tx-sender (get authorized-by funder-data)) (err u2))
    (map-set funders
      { funder-id: funder-id }
      (merge funder-data { active: false })
    )
    (ok true)
  )
)
