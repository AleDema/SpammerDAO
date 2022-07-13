import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Bool "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import M "mo:base/HashMap";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";

import Account "./Account";
import B "Book";
import GT "./Governance";
import T "./Types";

import Ledger "canister:ledger";
// import Neuron "canister:neuron";
// import Governance "ic:rrkah-fqaaa-aaaaa-aaaaq-cai";
// import Ledger "ic:ryjl3-tyaaa-aaaaa-aaaba-cai";

//what if proposal costs increases during current period? 
//what if there is a bug/need to upgrade?
//make vars stable
actor class Self() = this{

    var is_crowdfund_period : Bool = true;
    var is_proposal_period : Bool = false;
    var approved_next = false;
    var crowdfund_duration : Nat = 7; //days
    var crowdfund_start_date  : Int = Time.now(); 
    var crowdfund_end_date : Int = crowdfund_start_date + (60 * 1000 * 60 * 24 * 7);
    var proposal_submission_start_date  : Int = 0; 
    var proposal_submission_end_date : Int = proposal_submission_start_date + (60 * 1000 * 60 * 24 * 30);
    var proposer : Nat = 16392997059792243989; //ysms for now
   // var withdrawal_authorized_principal : Blob = Blob.fromArray([16392997059792243989]); //ysms for now
    var proposalCost : Nat = 10;
    var proposalPerDay : Nat = 4;
    var monthly_cost : Nat = proposalPerDay * proposalCost * 30;
    var amount_due : Nat = 0;
    var canister_balance : Nat = 0;
    var last_check : Time.Time = 0;
    var daily_quota_met = false;
    var completion_timestamp : Time.Time = 0;
    let HB_TICK_RATE = 1; //once every hour
    let ledger : Principal = Principal.fromActor(Ledger);
    let icp_fee: Nat = 10_000;
    // User balance datastructure
    private var book = B.Book();
    // private var book_stable : [var (Principal, Nat)] = [var];

    let Governance = actor "rrkah-fqaaa-aaaaa-aaaaq-cai" : GT.Service;

    public shared query func getCrowdfundStatus() : async Bool{
        return is_crowdfund_period;
    };

    type Data = { balance : Nat; endDate : Int ; deposit: Blob;};
    public func getCrowdfundData() : async Data {
        return { balance = canister_balance; endDate = crowdfund_end_date; deposit = await getDepositAddress();};
    };

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

    system func heartbeat() : async () {
        let now = Time.now();
        let nowInHours = hoursFromEpoch(now);
        if(nowInHours - hoursFromEpoch(last_check) >= HB_TICK_RATE){
            last_check := now;
            if(is_crowdfund_period) {
               ignore checkBalance();
            };

            if(is_proposal_period) {
                ignore checkProposals();
                //used to refund eventual leftovers from past period
                if (proposal_submission_end_date < Time.now()){
                    if (approved_next == false) is_proposal_period := false;
                    refundLeftovers();
                };

                //used to initialize next crowdfund, 7 days before current period ends
                if (proposal_submission_end_date - timeframeToNanos(7, #days)  < Time.now()){ //check this
                    is_crowdfund_period := true;
                };
            };
        };
    };



    func checkBalance() : async(){
        
        if (canister_balance >= monthly_cost){
            is_crowdfund_period:= false;
            if (is_proposal_period) approved_next := true;
            is_proposal_period:= true;
            proposal_submission_start_date:= Time.now()
        } else if(canister_balance < monthly_cost and crowdfund_end_date < Time.now()){
            approved_next := false;
            refundFailedCrowdfund();
        };
    };

    func refundLeftovers(){

    };

    func refundFailedCrowdfund(){

    };

    // public func withdrawAmountDue(account_id: Blob) : async T.WithdrawReceipt{
    //     // check user is authorized
    //   if (amount_due > icp_fee){
    //         Debug.print("Withdrawing amount due...");

    //         // Transfer amount back to user
    //         let icp_reciept =  await Ledger.transfer({
    //             memo: Nat64    = 0;
    //             from_subaccount = ?Account.defaultSubaccount();
    //             to = account_id;
    //             amount = { e8s = Nat64.fromNat(amount_due + icp_fee) };
    //             fee = { e8s = Nat64.fromNat(icp_fee) };
    //             created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
    //         });

    //         //subtract donors balances 

    //         switch icp_reciept {
    //             case (#Err e) {
    //                 // add tokens back to user account balance
    //                 //book.addTokens(caller,ledger,amount+icp_fee);
    //                 return #Err(#TransferFailure);
    //             };
    //             case _ {amount_due := 0;};
    //         };
    //         #Ok(amount_due);
    //         //send ICPs
    //     };

    //     return #Err(#TransferFailure);
    // };

    func checkProposals() : async (){
        if(daily_quota_met == false){
            var nProposals = 4; //actually get proposals here

            if (nProposals > proposalPerDay){
                nProposals := proposalPerDay; //used so even if more proposals are submitted there is no benefit;
            };

            if (nProposals == proposalPerDay){
                daily_quota_met:= true;
                completion_timestamp := Time.now();

            };

            if (daily_quota_met){
                amount_due := amount_due + (nProposals * proposalCost); //make this dynamic based on API data?
            };
        };

        if(getTimePassed(Time.now(), completion_timestamp, #days) > 1){
            daily_quota_met:= false;
        }

    };

    func myAccountId() : Account.AccountIdentifier {
        Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount())
    };


    func secsToNanos(s: Int): Int { 1_000_000_000 * s };
    
    func daysFromEpoch(timestamp : Time.Time) :  Int {
        var to_seconds = timestamp / 1_000_000_000;
        var daysPassed = to_seconds / 60 / 60 / 24;
        Debug.print(debug_show(timestamp));
        Debug.print(debug_show(daysPassed));
        return daysPassed;
    };

    func hoursFromEpoch(timestamp : Time.Time) :  Int {
        if(timestamp < 1) return 0;
        var hoursPassed = timestamp / 60 / 60 / 1_000_000_000 ;
        Debug.print(debug_show(timestamp));
        Debug.print(debug_show(hoursPassed));
        return hoursPassed;
    };

    func timeFromEpoc(timestamp : Time.Time, timeframe : TF) : Int {
        let normalize = timestamp / 1_000_000_000;
        switch(timeframe){
            case(#minutes) normalize / 60 ;
            case(#hours) normalize / 60 / 60 ;
            case(#days) normalize / 60 / 60 / 24  ;
        };
    };

    func timeframeToNanos(n : Time.Time, timeframe : TF) : Int{
        let normalize = n * 1_000_000_000;
        switch(timeframe){
            case(#minutes) normalize * 60 ;
            case(#hours) normalize * 60 * 60 ;
            case(#days) normalize * 60 * 60 * 24  ;
        };
    };

    func getTimePassed(recent_timestamp : Time.Time, old_timestamp : Time.Time, timeframe : TF) : Int{
        if (old_timestamp == 0) return recent_timestamp;
        timeFromEpoc(recent_timestamp, timeframe) - timeFromEpoc(old_timestamp, timeframe);
    };

    //LEDGER 

    // ===== DEPOSIT FUNCTIONS =====
    // Return the account ID specific to this user's subaccount
    public shared(msg) func getDepositAddress(): async Blob {
       //Principal.fromActor(this);
        Account.accountIdentifier(Principal.fromActor(this), Account.principalToSubaccount(msg.caller));
    };

    public shared(msg) func deposit(): async T.DepositReceipt {
        //Debug.print("Depositing Token: " # Principal.toText(token) # " LEDGER: " # Principal.toText(ledger));
       
            await depositIcp(msg.caller)
     
        // } else {
        //     await depositDip(msg.caller, token)
        // }
    };

    // After user transfers ICP to the target subaccount
    private func depositIcp(caller: Principal): async T.DepositReceipt {

        // Calculate target subaccount
        // NOTE: Should this be hashed first instead?
        let source_account = Account.accountIdentifier(Principal.fromActor(this), Account.principalToSubaccount(caller));

        // Check ledger for value
        let balance = await Ledger.account_balance({ account = source_account });

        // Transfer to default subaccount
        let icp_receipt = if (Nat64.toNat(balance.e8s) > icp_fee) {
            await Ledger.transfer({
                memo: Nat64    = 0;
                from_subaccount = ?Account.principalToSubaccount(caller);
                to = Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
                amount = { e8s = balance.e8s - Nat64.fromNat(icp_fee)};
                fee = { e8s = Nat64.fromNat(icp_fee) };
                created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
            })
        } else {
            return #Err(#BalanceLow);
        };

        switch icp_receipt {
            case ( #Err _) {
                return #Err(#TransferFailure);
            };
            case _ {};
        };
        let available = { e8s : Nat = Nat64.toNat(balance.e8s) - icp_fee };

        // keep track of deposited ICP
        book.addTokens(caller,ledger,available.e8s);

        // Return result
        #Ok(available.e8s)
    };

    // ===== WITHDRAW FUNCTIONS =====
    public shared(msg) func withdraw(amount: Nat, address: Principal) : async T.WithdrawReceipt {
        let account_id = Account.accountIdentifier(address, Account.defaultSubaccount());
        await withdrawIcp(msg.caller, amount, account_id)
    };

    private func withdrawIcp(caller: Principal, amount: Nat, account_id: Blob) : async T.WithdrawReceipt {
        Debug.print("Withdraw...");

        // remove withdrawal amount from book
        switch (book.removeTokens(caller, ledger, amount+icp_fee)){
            case(null){
                return #Err(#BalanceLow)
            };
            case _ {};
        };

        // Transfer amount back to user
        let icp_reciept =  await Ledger.transfer({
            memo: Nat64    = 0;
            from_subaccount = ?Account.defaultSubaccount();
            to = account_id;
            amount = { e8s = Nat64.fromNat(amount + icp_fee) };
            fee = { e8s = Nat64.fromNat(icp_fee) };
            created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
        });

        switch icp_reciept {
            case (#Err e) {
                // add tokens back to user account balance
                book.addTokens(caller,ledger,amount+icp_fee);
                return #Err(#TransferFailure);
            };
            case _ {};
        };
        #Ok(amount)
    };


   // GOVERNANCE CANISTER INTERACTIONS

  //creation date proposal_timestamp_seconds
  //proposer proposer : ?NeuronId; -> Nat
  //category topic : Int32;
  public func getPendingProposals(): async [ MyProposal] {
    let proposals : [GT.ProposalInfo] = await Governance.get_pending_proposals();
    var data = Buffer.Buffer<MyProposal>(0);
    var array : [ MyProposal] = [];
    for(i in proposals.keys()){
        let proposer1 : GT.NeuronId = Option.get(proposals[i].proposer, {id = 0:Nat64});
        if (proposer1.id != 0){
          let proposer2 : Nat64 = proposer1.id;
          let category = proposals[i].topic;
          let creation = proposals[i].proposal_timestamp_seconds;
          let item = MyProposal(creation, proposer2, category);
          data.add(item);
        }
    };
    return data.toArray();
  };


    // include_reward_status : [Int32];
    // before_proposal : ?NeuronId;
    // limit : Nat32;
    // exclude_topic : [Int32];
    // include_status : [Int32];
  public func getAllProposals(): async [ MyProposal] {
    let proposals : GT.ListProposalInfoResponse = await Governance.list_proposals({include_reward_status = [1,2,3];limit = 10000; before_proposal = null; exclude_topic = [1,2,3]; include_status = [];});
    var data = Buffer.Buffer<MyProposal>(0);
    var array : [MyProposal] = [];
    for(i in proposals.proposal_info.keys()){
        let proposer1 : GT.NeuronId = Option.get(proposals.proposal_info[i].proposer, {id = 0:Nat64});
        if (proposer1.id != 0){
          let proposer2 : Nat64 = proposer1.id;
          let category = proposals.proposal_info[i].topic;
          let creation = proposals.proposal_info[i].proposal_timestamp_seconds;
          let item = MyProposal(creation, proposer2, category);
          data.add(item);
        }
    };
    return data.toArray();
  };


  public func getAllDailyProposals(): async [ MyProposal] {
    let proposals : GT.ListProposalInfoResponse = await Governance.list_proposals({include_reward_status = [1,2,3];limit = 10000; before_proposal = null; exclude_topic = [1,2,3]; include_status = [];});
    var data = Buffer.Buffer<MyProposal>(0);
    var array : [MyProposal] = [];
    let now = daysFromEpoch(Time.now());
    label fillArray for(i in proposals.proposal_info.keys()){
        let proposer1 : GT.NeuronId = Option.get(proposals.proposal_info[i].proposer, {id = 0:Nat64});
        if (proposer1.id != 0){
          let proposer2 : Nat64 = proposer1.id;
          let category = proposals.proposal_info[i].topic;
          let creation = proposals.proposal_info[i].proposal_timestamp_seconds;
          let old = daysFromEpoch(secsToNanos(Nat64.toNat(creation)));
          let difference = now - old;
          if(difference >= 1) {break fillArray;};
          let item = MyProposal(creation, proposer2, category);
          data.add(item);
        }
    };
    return data.toArray();
  };


  public func getDailyProposalsCountById(id : Nat64) : async Nat{
    let proposals = await getAllDailyProposals();
    //let now = daysFromEpoch(Time.now());
    var count = 0 : Nat;
      for(i in proposals.keys()){
        //let old = daysFromEpoch(secsToNanos(Nat64.toNat(proposals[i]._creation)));
        //let difference = now - old;
        //TEMP
        if (proposals[i]._proposer == id){
          count += 1;
        }
    };
    return count;
  };

  public func getNProposalsById(id : Nat64) : async Nat{
    let proposals = await getPendingProposals();
    var count = 0 : Nat;
      for(i in proposals.keys()){
        if (proposals[i]._proposer == id){
          count += 1;
        }
    };
    return count;
  };

//timeframe == number of days
//   public func getNProposalsByIdInTimeframe(id : Nat64, timeframe : Nat64) : async Nat{
//     let proposals = await getPendingProposals();
//     let now = Time.now();
//     let now2 = epochToDate(now);
//     var count = 0 : Nat;
//       for(i in proposals.keys()){
//         let blah = epochToDate(secsToNanos(Nat64.toNat(proposals[i]._creation)));
//         let difference = (now2 - blah) / EPOCH_TIME_DAY;
//         //TEMP
//         if (proposals[i]._proposer == id and difference <=  Nat64.toNat(timeframe)){
//           count += 1;
//         }
//     };
//     return count;
//   };

  public func getDailyPendingProposalsCountById(id : Nat64) : async Nat{
    let proposals = await getPendingProposals();
    let now = daysFromEpoch(Time.now());
    var count = 0 : Nat;
      for(i in proposals.keys()){
        let old = daysFromEpoch(secsToNanos(Nat64.toNat(proposals[i]._creation)));
        let difference = now - old;
        //TEMP
        if (proposals[i]._proposer == id and difference == 0){
          count += 1;
        }
    };
    return count;
  };
};
