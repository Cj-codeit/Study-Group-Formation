# Study Group Formation Smart Contract

A decentralized system for creating and managing study groups with transparent membership.

## Features

- Study group creation with capacity limits
- Member joining and leaving
- Role-based permissions
- Meeting schedule management
- Active membership tracking

## Contract Functions

### Public Functions

- `create-study-group` - Create new study group
- `join-group` - Join an existing group
- `leave-group` - Leave a group (non-leaders only)
- `update-schedule` - Update meeting schedule (leader only)
- `close-group` - Close a study group (creator only)

### Read-Only Functions

- `get-study-group` - Get group details
- `get-group-member` - Get member information
- `is-member` - Check active membership
- `get-user-groups-count` - Get user's group count
- `get-group-nonce` - Get current group counter

## Usage

Deploy with Clarinet to facilitate study group formation and management.