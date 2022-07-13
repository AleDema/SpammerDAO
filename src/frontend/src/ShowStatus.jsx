import React from "react";
import { backend } from "../../declarations/backend";
import {
  toHexString,
  hexToBytes,
  principalToAccountDefaultIdentifier,
} from "./utils.js";

export default function ShowStatus() {
  const [timeLeft, setTimeLeft] = React.useState();
  const [moneyRaised, setMoneyRaised] = React.useState();
  const [deposit, setDeposit] = React.useState();

  const getResponse = async () => {
    const data = await backend.getCrowdfundData();
    // setTimeLeft(data.timeLeft);
    // setMoneyRaised(data.balance);
    setDeposit(toHexString(data.deposit));
    console.log(data.balance);
    console.log(toHexString(data.deposit));
    console.log(data.deposit);
  };

  React.useEffect(() => {
    getResponse();
  }, []);

  return (
    <>
      {/* <div>{timeLeft}</div> */}
      <div>{moneyRaised}</div>
      <div>{deposit}</div>
      <div>deposit</div>
    </>
  );
}
