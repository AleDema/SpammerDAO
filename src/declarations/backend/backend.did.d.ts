import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Data {
  'balance' : bigint,
  'endDate' : bigint,
  'deposit' : Array<number>,
}
export type DepositErr = { 'TransferFailure' : null } |
  { 'BalanceLow' : null };
export type DepositReceipt = { 'Ok' : bigint } |
  { 'Err' : DepositErr };
export interface MyProposal {
  '_creation' : bigint,
  '_category' : number,
  '_proposer' : bigint,
}
export interface Self {
  'deposit' : ActorMethod<[], DepositReceipt>,
  'getAllDailyProposals' : ActorMethod<[], Array<MyProposal>>,
  'getAllProposals' : ActorMethod<[], Array<MyProposal>>,
  'getCrowdfundData' : ActorMethod<[], Data>,
  'getCrowdfundStatus' : ActorMethod<[], boolean>,
  'getDailyPendingProposalsCountById' : ActorMethod<[bigint], bigint>,
  'getDailyProposalsCountById' : ActorMethod<[bigint], bigint>,
  'getDepositAddress' : ActorMethod<[], Array<number>>,
  'getNProposalsById' : ActorMethod<[bigint], bigint>,
  'getPendingProposals' : ActorMethod<[], Array<MyProposal>>,
  'withdraw' : ActorMethod<[bigint, Principal], WithdrawReceipt>,
}
export type WithdrawErr = { 'TransferFailure' : null } |
  { 'BalanceLow' : null };
export type WithdrawReceipt = { 'Ok' : bigint } |
  { 'Err' : WithdrawErr };
export interface _SERVICE extends Self {}
