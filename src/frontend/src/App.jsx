import * as React from "react";
import logo from "../assets/logo.png";
import { backend } from "../../declarations/backend";
import ShowStatus from "./ShowStatus";
import ShowSuccess from "./ShowSuccess";

const App = () => {
  const [isCrowdfundMode, setCrowdfundMode] = React.useState(true);

  const getResponse = async () => {
    console.log("test");
    const isCrowdfundMode1 = await backend.getCrowdfundStatus();
    setCrowdfundMode(isCrowdfundMode1);
    console.log(isCrowdfundMode);
  };

  React.useEffect(() => {
    getResponse();
  }, []);

  return (
    <main>
      <img src={logo} alt="DFINITY logo" />
      <React.Suspense fallback={<h1>Loading...</h1>}>
        {isCrowdfundMode ? (
          <ShowStatus></ShowStatus>
        ) : (
          <ShowSuccess></ShowSuccess>
        )}
      </React.Suspense>
    </main>
  );
};

export default App;
