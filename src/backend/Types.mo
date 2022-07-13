import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
import Int32 "mo:base/Int32";
import Time "mo:base/Time";


module {

    type Data = { balance : Nat; endDate : Int ; };

    type TF = {
        #minutes;
        #hours;
        #days;
    }; 

    type Result<T,E> = Result.Result<T, E>;

    class MyProposal(creation : Nat64, proposer: Nat64, category: Int32) {
        public let _creation : Nat64 = creation;
        public let _proposer : Nat64 = proposer;
        public let _category : Int32 = category;
    };

    public type Token = Principal;

    public type OrderId = Nat32;
  
    public type Order = {
        id: OrderId;
        owner: Principal;
        from: Token;
        fromAmount: Nat;
        to: Token;
        toAmount: Nat;
    };
    
    // ledger types
    public type Operation = {
        #approve;
        #mint;
        #transfer;
        #transferFrom;
    };

 
    public type TransactionStatus = {
        #succeeded;
        #failed;
    };

    public type TxRecord = {
        caller: ?Principal;
        op: Operation; // operation type
        index: Nat; // transaction index
        from: Principal;
        to: Principal;
        amount: Nat;
        fee: Nat;
        timestamp: Time.Time;
        status: TransactionStatus;
    };

    // Dip20 token interface
    public type TxReceipt = {
        #Ok: Nat;
        #Err: {
            #InsufficientAllowance;
            #InsufficientBalance;
            #ErrorOperationStyle;
            #Unauthorized;
            #LedgerTrap;
            #ErrorTo;
            #Other;
            #BlockUsed;
            #AmountTooSmall;
        };
    };

    public type Metadata = {
        logo : Text; // base64 encoded logo or logo url
        name : Text; // token name
        symbol : Text; // token symbol
        decimals : Nat8; // token decimal
        totalSupply : Nat; // token total supply
        owner : Principal; // token owner
        fee : Nat; // fee for update calls
    };


    public type DIPInterface = actor {
        transfer : (Principal,Nat) ->  async TxReceipt;
        transferFrom : (Principal,Principal,Nat) -> async TxReceipt;
        allowance : (owner: Principal, spender: Principal) -> async Nat;
        getMetadata: () -> async Metadata;
    };

    // return types
    public type OrderPlacementErr = {
        #InvalidOrder;
        #OrderBookFull;
    };
    public type OrderPlacementReceipt = {
        #Ok: ?Order;
        #Err: OrderPlacementErr;
    };
    public type CancelOrderErr = {
        #NotExistingOrder;
        #NotAllowed;
    };
    public type CancelOrderReceipt = {
        #Ok: OrderId;
        #Err: CancelOrderErr;
    };
    public type WithdrawErr = {
        #BalanceLow;
        #TransferFailure;
    };
    public type WithdrawReceipt = {
        #Ok: Nat;
        #Err: WithdrawErr;  
    };
    public type DepositErr = {
        #BalanceLow;
        #TransferFailure;
    };
    public type DepositReceipt = {
        #Ok: Nat;
        #Err: DepositErr;
    };
    public type Balance = {
        owner: Principal;
        token: Token;
        amount: Nat;
    };

}