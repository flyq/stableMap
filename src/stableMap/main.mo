/**
 * Module     : token.mo
 * Copyright  : 2021 DFinance Team
 * License    : Apache 2.0 with LLVM Exception
 * Maintainer : DFinance Team <hello@dfinance.ai>
 * Stability  : Experimental
 */

import HashMap "./stableMap";
import Principal "mo:base/Principal";
import Types "./types";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Nat "mo:base/Nat";
import ExperimentalCycles "mo:base/ExperimentalCycles";

shared(msg) actor class Token(
    _logo: Text,
    _name: Text, 
    _symbol: Text,
    _decimals: Nat, 
    _totalSupply: Nat, 
    _owner: Principal
    ) {
    type Operation = Types.Operation;
    type OpRecord = Types.OpRecord;
    type Metadata = {
        logo : Text;
        name : Text;
        symbol : Text;
        decimals : Nat;
        totalSupply : Nat;
        owner : Principal;
        historySize : Nat;
        deployTime: Time.Time;
        fee : Nat;
        feeTo : Principal;
        holderNumber : Nat;
        cycles : Nat;
    };

    private stable var owner_ : Principal = _owner;
    private stable var logo_ : Text = _logo;
    private stable var name_ : Text = _name;
    private stable var decimals_ : Nat = _decimals;
    private stable var symbol_ : Text = _symbol;
    private stable var totalSupply_ : Nat = _totalSupply;
    private stable var blackhole : Principal = Principal.fromText("aaaaa-aa");
    private stable var feeTo : Principal = owner_;
    private stable var fee : Nat = 0;
    private stable var balances = HashMap.defaults<Principal, Nat>();
    private stable var allowances = HashMap.defaults<Principal, HashMap.HashMap<Principal, Nat>>();
    balances := HashMap.put(balances, owner_, totalSupply_, Principal.hash, Principal.equal);
    private stable let genesis : OpRecord = {
        caller = owner_;
        op = #init;
        index = 0;
        from = blackhole;
        to = owner_;
        amount = totalSupply_;
        fee = 0;
        timestamp = Time.now();
    };
    private stable var ops : [OpRecord] = [genesis];

    private func addRecord(
        caller: Principal, op: Operation, from: Principal, to: Principal, amount: Nat,
        fee: Nat, timestamp: Time.Time
    ) {
        let index = ops.size();
        let o : OpRecord = {
            caller = caller;
            op = op;
            index = index;
            from = from;
            to = to;
            amount = amount;
            fee = fee;
            timestamp = timestamp;
        };
        ops := Array.append(ops, [o]);
    };

    private func _chargeFee(from: Principal, fee: Nat) {
        if(fee > 0) {
            _transfer(from, feeTo, fee);
        };
    };

    private func _transfer(from: Principal, to: Principal, value: Nat) {
        let from_balance = _balanceOf(from);
        let from_balance_new : Nat = from_balance - value;
        if (from_balance_new != 0) { 
            balances := HashMap.put(balances, from, from_balance_new, Principal.hash, Principal.equal);
        } else { 
            balances := HashMap.delete(balances, from, Principal.hash, Principal.equal);
        };

        let to_balance = _balanceOf(to);
        let to_balance_new : Nat = to_balance + value;
        if (to_balance_new != 0) { 
            balances := HashMap.put(balances, to, to_balance_new, Principal.hash, Principal.equal);
        };
    };

    private func _balanceOf(who: Principal) : Nat {
        switch (HashMap.get(balances, who, Principal.hash, Principal.equal)) {
            case (?balance) { return balance; };
            case (_) { return 0; };
        }
    };

    private func _allowance(owner: Principal, spender: Principal) : Nat {
        switch (HashMap.get(allowances, owner, Principal.hash, Principal.equal)) {
            case (?allowance_owner) {
                switch(HashMap.get(allowance_owner, spender, Principal.hash, Principal.equal)) {
                    case (?allowance) { return allowance; };
                    case (_) { return 0; };
                }
            };
            case (_) { return 0; };
        }
    };

    public shared(msg) func setFeeTo(to: Principal) : async Bool {
        assert(msg.caller == owner_);
        feeTo := to;
        return true;
    };

    public shared(msg) func setFee(_fee: Nat) : async Bool {
        assert(msg.caller == owner_);
        fee := _fee;
        return true;
    };

    public shared(msg) func setLogo(logo: Text) : async Bool {
        assert(msg.caller == owner_);
        logo_ := logo;
        return true;
    };

    /// Transfers value amount of tokens to Principal to.
    public shared(msg) func transfer(to: Principal, value: Nat) : async Bool {
        if (value < fee) { return false; };
        if (_balanceOf(msg.caller) < value) { return false; };
        _chargeFee(msg.caller, fee);
        _transfer(msg.caller, to, value - fee);
        addRecord(msg.caller, #transfer, msg.caller, to, value, fee, Time.now());
        return true;
    };

    /// Transfers value amount of tokens from Principal from to Principal to.
    public shared(msg) func transferFrom(from: Principal, to: Principal, value: Nat) : async Bool {
        if (value < fee) { return false; };
        if (_balanceOf(from) < value) { return false; };
        let allowed : Nat = _allowance(from, msg.caller);
        if (allowed < value) { return false; };
        _chargeFee(from, fee);
        _transfer(from, to, value - fee);
        let allowed_new : Nat = allowed - value;
        if (allowed_new != 0) {
            var allowance_from = Option.unwrap(HashMap.get(allowances, from, Principal.hash, Principal.equal));
            allowance_from := HashMap.put(allowance_from, msg.caller, allowed_new, Principal.hash, Principal.equal);
            allowances := HashMap.put(allowances, from, allowance_from, Principal.hash, Principal.equal);
        } else {
            if (allowed != 0) {
                var allowance_from = Option.unwrap(HashMap.get(allowances, from, Principal.hash, Principal.equal));
                allowance_from := HashMap.delete(allowance_from, msg.caller, Principal.hash, Principal.equal);
                if (HashMap.size(allowance_from) == 0) { 
                    allowances := HashMap.delete(allowances, from, Principal.hash, Principal.equal);
                }
                else { 
                    allowances := HashMap.put(allowances, from, allowance_from, Principal.hash, Principal.equal);
                };
            };
        };
        addRecord(from, #transfer, from, to, value, fee, Time.now());
        return true;
    };

    public query func balanceOf(who: Principal) : async Nat {
        return _balanceOf(who);
    };

    public query func allowance(owner: Principal, spender: Principal) : async Nat {
        return _allowance(owner, spender);
    };

    public query func totalSupply() : async Nat {
        return totalSupply_;
    };

    public query func logo() : async Text {
        return logo_;
    };

    public query func name() : async Text {
        return name_;
    };

    public query func decimals() : async Nat {
        return decimals_;
    };

    public query func symbol() : async Text {
        return symbol_;
    };

    public query func owner() : async Principal {
        return owner_;
    };

    public query func getFeeTo() : async Principal {
        return feeTo;
    };

    public query func getFee() : async Nat {
        return fee;
    };

    public query func getHolderNumber() : async Nat {
        return HashMap.size(balances);
    };

    /// Get History by index.
    public query func getHistoryByIndex(index: Nat) : async OpRecord {
        return ops[index];
    };

    /// Get history
    public query func getHistory(start: Nat, num: Nat) : async [OpRecord] {
        var ret: [OpRecord] = [];
        var i = start;
        while(i < start + num and i < ops.size()) {
            ret := Array.append(ret, [ops[i]]);
            i += 1;
        };
        return ret;
    };

    public query func getUserOpAmount(a: Principal) : async Nat {
        var res: Nat = 0;
        for (i in ops.vals()) {
            if (i.caller == a or i.from == a or i.to == a) {
                res += 1;
            };
        };
        return res;
    };

    public query func getUserHistory(a: Principal, start: Nat, num: Nat) : async [OpRecord] {
        var res: [OpRecord] = [];
        var index: Nat = 0;
        for (i in ops.vals()) {
            if (i.caller == a or i.from == a or i.to == a) {
                if(index >= start and index < start + num) {
                    res := Array.append<OpRecord>(res, [i]);
                };
                index += 1;
            };
        };
        return res;
    };

    /// Get history by account.
    public query func getHistoryByAccount(a: Principal) : async [OpRecord] {
        var res: [OpRecord] = [];
        for (i in ops.vals()) {
            if (i.caller == a or i.from == a or i.to == a) {
                res := Array.append<OpRecord>(res, [i]);
            };
        };
        return res;
    };
    
    /// Get all update call history.
    public query func allHistory() : async [OpRecord] {
        return ops;
    };


    public query func getCycles() : async Nat {
        return ExperimentalCycles.balance();
    };

    public query func getMetadata() : async Metadata {
        return {
            logo = logo_;
            name = name_;
            symbol = symbol_;
            decimals = decimals_;
            totalSupply = totalSupply_;
            owner = owner_;
            historySize = ops.size();
            deployTime = genesis.timestamp;
            fee = fee;
            feeTo = feeTo;
            holderNumber = HashMap.size(balances);
            cycles = ExperimentalCycles.balance();
        };
    };
};