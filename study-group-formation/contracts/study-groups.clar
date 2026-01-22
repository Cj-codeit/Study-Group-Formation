;; Study Group Formation Contract
;; Decentralized study group creation and member management

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-group-full (err u102))
(define-constant err-already-member (err u103))
(define-constant err-not-member (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-session-not-found (err u106))
(define-constant err-invalid-rating (err u107))
(define-constant err-already-rated (err u108))

;; Data Variables
(define-data-var group-nonce uint u0)
(define-data-var session-nonce uint u0)

;; Data Maps
(define-map study-groups
  uint
  {
    name: (string-ascii 100),
    subject: (string-ascii 100),
    creator: principal,
    max-members: uint,
    current-members: uint,
    meeting-schedule: (string-ascii 200),
    active: bool
  }
)

(define-map group-members
  { group-id: uint, member: principal }
  {
    joined-at: uint,
    role: (string-ascii 20),
    active: bool
  }
)

(define-map user-groups-count principal uint)

(define-map study-sessions
  uint
  {
    group-id: uint,
    session-name: (string-ascii 100),
    date: uint,
    duration: uint,
    completed: bool
  }
)

(define-map session-attendance
  { session-id: uint, member: principal }
  bool
)

(define-map member-ratings
  { group-id: uint, rater: principal, rated: principal }
  {
    rating: uint,
    timestamp: uint
  }
)

(define-map group-resources
  { group-id: uint, resource-id: uint }
  {
    title: (string-ascii 100),
    url: (string-ascii 200),
    added-by: principal,
    added-at: uint
  }
)

;; Read-only functions
(define-read-only (get-study-group (group-id uint))
  (map-get? study-groups group-id)
)

(define-read-only (get-group-member (group-id uint) (member principal))
  (map-get? group-members { group-id: group-id, member: member })
)

(define-read-only (is-member (group-id uint) (member principal))
  (match (map-get? group-members { group-id: group-id, member: member })
    membership (get active membership)
    false
  )
)

(define-read-only (get-user-groups-count (user principal))
  (default-to u0 (map-get? user-groups-count user))
)

(define-read-only (get-group-nonce)
  (var-get group-nonce)
)

;; Public functions
;; #[allow(unchecked_data)]
(define-public (create-study-group 
  (name (string-ascii 100))
  (subject (string-ascii 100))
  (max-members uint)
  (meeting-schedule (string-ascii 200)))
  (let
    (
      (group-id (var-get group-nonce))
      (creator tx-sender)
    )
    (map-set study-groups group-id
      {
        name: name,
        subject: subject,
        creator: creator,
        max-members: max-members,
        current-members: u1,
        meeting-schedule: meeting-schedule,
        active: true
      }
    )
    (map-set group-members 
      { group-id: group-id, member: creator }
      {
        joined-at: stacks-block-height,
        role: "leader",
        active: true
      }
    )
    (map-set user-groups-count creator (+ (get-user-groups-count creator) u1))
    (var-set group-nonce (+ group-id u1))
    (ok group-id)
  )
)

;; #[allow(unchecked_data)]
(define-public (join-group (group-id uint))
  (let
    (
      (group (unwrap! (map-get? study-groups group-id) err-not-found))
      (member tx-sender)
      (existing-membership (map-get? group-members { group-id: group-id, member: member }))
    )
    (asserts! (get active group) err-unauthorized)
    (asserts! (< (get current-members group) (get max-members group)) err-group-full)
    (asserts! (is-none existing-membership) err-already-member)
    (map-set group-members 
      { group-id: group-id, member: member }
      {
        joined-at: stacks-block-height,
        role: "member",
        active: true
      }
    )
    (map-set study-groups group-id
      (merge group { current-members: (+ (get current-members group) u1) })
    )
    (map-set user-groups-count member (+ (get-user-groups-count member) u1))
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (leave-group (group-id uint))
  (let
    (
      (group (unwrap! (map-get? study-groups group-id) err-not-found))
      (member tx-sender)
      (membership (unwrap! (map-get? group-members { group-id: group-id, member: member }) err-not-member))
    )
    (asserts! (get active membership) err-not-member)
    (asserts! (not (is-eq (get role membership) "leader")) err-unauthorized)
    (map-set group-members 
      { group-id: group-id, member: member }
      (merge membership { active: false })
    )
    (map-set study-groups group-id
      (merge group { current-members: (- (get current-members group) u1) })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (update-schedule (group-id uint) (new-schedule (string-ascii 200)))
  (let
    (
      (group (unwrap! (map-get? study-groups group-id) err-not-found))
      (membership (unwrap! (map-get? group-members { group-id: group-id, member: tx-sender }) err-not-member))
    )
    (asserts! (is-eq (get role membership) "leader") err-unauthorized)
    (map-set study-groups group-id (merge group { meeting-schedule: new-schedule }))
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (close-group (group-id uint))
  (let
    (
      (group (unwrap! (map-get? study-groups group-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator group)) err-unauthorized)
    (map-set study-groups group-id (merge group { active: false }))
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (create-session 
  (group-id uint)
  (session-name (string-ascii 100))
  (date uint)
  (duration uint))
  (let
    (
      (group (unwrap! (map-get? study-groups group-id) err-not-found))
      (membership (unwrap! (map-get? group-members { group-id: group-id, member: tx-sender }) err-not-member))
      (session-id (var-get session-nonce))
    )
    (asserts! (is-eq (get role membership) "leader") err-unauthorized)
    (asserts! (get active group) err-unauthorized)
    (map-set study-sessions session-id
      {
        group-id: group-id,
        session-name: session-name,
        date: date,
        duration: duration,
        completed: false
      }
    )
    (var-set session-nonce (+ session-id u1))
    (ok session-id)
  )
)

;; #[allow(unchecked_data)]
(define-public (mark-attendance (session-id uint))
  (let
    (
      (session (unwrap! (map-get? study-sessions session-id) err-session-not-found))
      (group-id (get group-id session))
      (membership (unwrap! (map-get? group-members { group-id: group-id, member: tx-sender }) err-not-member))
    )
    (asserts! (get active membership) err-not-member)
    (map-set session-attendance { session-id: session-id, member: tx-sender } true)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (complete-session (session-id uint))
  (let
    (
      (session (unwrap! (map-get? study-sessions session-id) err-session-not-found))
      (group-id (get group-id session))
      (membership (unwrap! (map-get? group-members { group-id: group-id, member: tx-sender }) err-not-member))
    )
    (asserts! (is-eq (get role membership) "leader") err-unauthorized)
    (map-set study-sessions session-id (merge session { completed: true }))
    (ok true)
  )
)

(define-read-only (get-session (session-id uint))
  (map-get? study-sessions session-id)
)

(define-read-only (get-attendance (session-id uint) (member principal))
  (default-to false (map-get? session-attendance { session-id: session-id, member: member }))
)

(define-read-only (get-session-nonce)
  (var-get session-nonce)
)

(define-read-only (is-session-completed (session-id uint))
  (match (map-get? study-sessions session-id)
    session (get completed session)
    false
  )
)