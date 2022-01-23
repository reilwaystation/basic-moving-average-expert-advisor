
//Fast EMA input
input int fastEmaInput = 200;
input ENUM_MA_METHOD fastEmaMethodInput = MODE_EMA;
input ENUM_APPLIED_PRICE fastEmaAppliePriceInput = PRICE_CLOSE;

//Slow EMA input
input int slowEmaInput = 400;
input ENUM_MA_METHOD slowEmaMethodInput = MODE_EMA;
input ENUM_APPLIED_PRICE slowEmaAppliePriceInput = PRICE_CLOSE;

// TP/SL input
input int minCandlePoints = 20;
input int tpPercent = 50;
input int slPercent = 50;

// Standard Input
input double lotSize = 0.01;
input string tradeComment = __FILE__;
input int magicNumber = 212121;

double MinCandleSize;

// MQL5 specific
#ifdef __MQL5__
   #include    <Trade/Trade.mqh>;
   CTrade      Trade;
   CPosition   PositionInfo;

   int         HandleFast;
   int         HandleSlow;
   double      BufferFast[];
   double      BufferSlow[];
#endif 

// Check if the new bar appeared
bool IsNewBar()
  {
   datetime currentTime = iTime(Symbol(), Period(), 0);
   static datetime priorTime = currentTime;
   bool results = (currentTime !=priorTime);
   return results;
  }

int OnInit()
  {
      MinCandleSize = minCandlePoints * Point();
      return(CustomInit());
  }

void OnTick()
  {
      // exit if trading is not allowed
      if (!(bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) return;
      
      // once per bar
      if (!IsNewBar()) return;
      
      // exit if there is already an open trade
      if (TradeCount() > 0) return;
        
      // get indicator values
      double fastMA = 0;
      double slowMA = 0;
      GetMA(fastMA, slowMA);
      
      // get close values
      double close2 = iClose(Symbol(), Period(), 2);
      double close1 = iClose(Symbol(), Period(), 1);
      double candleSize = iHigh(Symbol(), Period(), 1) - iLow(Symbol(), Period(), 1);
      
      //declare common variables
      double tpSize;
      double slSize;
      double tpPrice;
      double slPrice;
      double openPrice;
      
      // buy condition
      if (fastMA>slowMA && close1 > slowMA && close2 < slowMA && candleSize=MinCandleSize)
      {
         tpSize = candleSize * tpPercent / 100;
         slSize = candleSize * slPercent / 100;
         openPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         tpPrice = NormalizeDouble(openPrice + tpSize, Digits());
         slPrice = NormalizeDouble(openPrice - slSize, Digits());
         OpenTrade(ORDER_TYPE_BUY), openPrice, slPrice, tpPrice);
      }
      
      // sell condition
      if (fastMA<slowMA && close1 < slowMA && close2 > slowMA && candleSize=MinCandleSize)
      {
         tpSize = candleSize * tpPercent / 100;
         slSize = candleSize * slPercent / 100;
         openPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         tpPrice = NormalizeDouble(openPrice - tpSize, Digits());
         slPrice = NormalizeDouble(openPrice + slSize, Digits());
         OpenTrade(ORDER_TYPE_SELL), openPrice, slPrice, tpPrice);
      }
  }

// MQL5 specific
#ifdef __MQL5__
   int CustomInit()
   {
      Trade.SetExpertMagicNumber(magicNumber);
      HandleFast = iMA(Symbol(), Period(), fastEmaInput, 0, fastEmaMethodInput, fastEmaAppliePriceInput);
      if (HandleFast == INVALID_HANDLE) return(INIT_FAILED);
      
      HandleSlow = iMA(Symbol(), Period(), slowEmaInput,0, slowEmaMethodInput, slowEmaAppliePriceInput);
      if (HandleFast == INVALID_HANDLE) return(INIT_FAILED);
      
      ArraySetAsSeries(BufferFast, true);
      ArraySetAsSeries(BufferSlow, true);
      return (INIT_SUCCEEDED);
   }
   
   void GetMA(double &fastMA, double &slowMA)
   {
      CopyBuffer(HandleFast, 0, 0, 1,BufferFast);
      CopyBuffer(HandleSlow, 0, 0, 1,BufferSlow);
      fastMA = BufferFast[0];
      slowMA = BufferSlow[0];
      return;
   }
   
   void OpenTrade(int type, double openPrice, double slPrice, double tpPrice)
   {
      Trade.PositionOpen(Symbol(), (ENUM_ORDER_TYPE)type, lotSize, openPrice, slPrice, tpPrice, tradeComment);
   }
   
   int TradeCount(
   {
      int tradeCount = 0;
      int count = PositionsTotal();
      
      for (int i=0; i < count; i++)
      {
         if (!PositionInfo.SelectByIndex(i)) continue;
         if (PositionInfo.Symbol() != Symbol() || PositionInfo.Magic() != magicNumber) continue;
         tradeCount++
      }
      return(tradeCount)
   }
   
#endif 

// MQL4 specific
#ifdef __MQL4__
   int CustomInit()
   {
      return (INIT_SUCCEEDED);
   }
   
   void GetMA(double &fastMA, double &slowMA)
   {
      fastMA = iMA(Symbol(), Period(), fastEmaInput, 0, fastEmaMethodInput, fastEmaAppliePriceInput, 0);
      slowMA = iMA(Symbol(), Period(), slowEmaInput,0, slowEmaMethodInput, slowEmaAppliePriceInput, 0);
      return;
   }
   
   void OpenTrade(int type, double openPrice, double slPrice, double tpPrice)
   {
      if (OrderSend(Symbol(), type, lotSize, openPrice, 0, slPrice, tpPrice, tradeComment, magicNumber)){}
   }
   
   int TradeCount()
   {
      int tradeCount = 0;
      int count = OrdersTotal();
      
      for (int i=0; i < count; i++)
      {
         if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
         if (OrderSymbol() != Symbol() || OrderMagicNumber() != magicNumber) continue;
         tradeCount++;
      }
      return(tradeCount);
   }
#endif 