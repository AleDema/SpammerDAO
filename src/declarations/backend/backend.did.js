export const idlFactory = ({ IDL }) => {
  const DepositErr = IDL.Variant({
    'TransferFailure' : IDL.Null,
    'BalanceLow' : IDL.Null,
  });
  const DepositReceipt = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : DepositErr });
  const MyProposal = IDL.Record({
    '_creation' : IDL.Nat64,
    '_category' : IDL.Int32,
    '_proposer' : IDL.Nat64,
  });
  const Data = IDL.Record({
    'balance' : IDL.Nat,
    'endDate' : IDL.Int,
    'deposit' : IDL.Vec(IDL.Nat8),
  });
  const WithdrawErr = IDL.Variant({
    'TransferFailure' : IDL.Null,
    'BalanceLow' : IDL.Null,
  });
  const WithdrawReceipt = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : WithdrawErr });
  const Self = IDL.Service({
    'deposit' : IDL.Func([], [DepositReceipt], []),
    'getAllDailyProposals' : IDL.Func([], [IDL.Vec(MyProposal)], []),
    'getAllProposals' : IDL.Func([], [IDL.Vec(MyProposal)], []),
    'getCrowdfundData' : IDL.Func([], [Data], []),
    'getCrowdfundStatus' : IDL.Func([], [IDL.Bool], ['query']),
    'getDailyPendingProposalsCountById' : IDL.Func([IDL.Nat64], [IDL.Nat], []),
    'getDailyProposalsCountById' : IDL.Func([IDL.Nat64], [IDL.Nat], []),
    'getDepositAddress' : IDL.Func([], [IDL.Vec(IDL.Nat8)], []),
    'getNProposalsById' : IDL.Func([IDL.Nat64], [IDL.Nat], []),
    'getPendingProposals' : IDL.Func([], [IDL.Vec(MyProposal)], []),
    'withdraw' : IDL.Func([IDL.Nat, IDL.Principal], [WithdrawReceipt], []),
  });
  return Self;
};
export const init = ({ IDL }) => { return []; };
