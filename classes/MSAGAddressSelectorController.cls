public with sharing class MSAGAddressSelectorController implements TestUtils.ITestableClass {
	
	public MSAGAddressSelectorController(){}
	
	@RemoteAction
	public static String AddressLookup(String city, String state, String street) {
		
		integraWS.SFMSAGAddressView[] views = ICCWrapper.searchMSAGAddress(city, state, street);
		String Table = '';
		String TableStart = '<table class="msagAddrTbl">';
		String TableHeader = '<tr><th>selected</th><th>predir</th><th>street</th><th>housestart</th><th>houseend</th><th>eob</th><th>city</th><th>PSAP</th><th>state</th><th>postdir</th><th>Source</th></tr>';
		String TableEnd = '</table>';
		Table = TableStart + TableHeader;
		Integer RowNum = 0;
		if(views != null && views.size() > 0)
		{
			for(integraWS.SFMSAGAddressView view : views)
			{
				Table += msagViewToTableRow(view, RowNum++);
			}
		}
		Table += TableEnd;
		return Table;
	}
	
	public static String msagViewToTableRow(integraWS.SFMSAGAddressView view, Integer RowNum)
	{
		if(view != null)
		{
			String CssClass = (Math.mod(RowNum, 2) == 0? 'msagAddrTblRow' : 'msagAddrTblAltRow');
			String trStart = '<tr class="'+ CssClass + ' msagTblRow">';
			String tdSelected = '<td class="tdSelected"><input type="checkbox" id="cbSelectedRow'+String.valueOf(RowNum)+'"></td>';
			String tdPredir = '<td class="preDir">' + view.PreDirectional + '</td>';
			String tdStreet = '<td class="street">' + view.Street + '</td>';
			String tdHouseStart = '<td class="houseStart">' + view.HouseStart + '</td>';
			String tdHouseEnd = '<td class="houseEnd">' + view.HouseEnd + '</td>';
			String tdHouseEOB = '<td class="houseEOB">' + view.HouseEOB + '</td>';
			String tdCity = '<td class="city">'+view.City+'</td>';
			String tdPSAP = '<td>' + view.PSAP + '</td>';
			String tdState = '<td class="state">' + view.State + '</td>';
			String tdPostdir = '<td class="postDir">' + view.PostDirectional + '</td>';
			String tdSource = '<td>' + view.Source + '</td>';
			String trEnd = '</tr>';
		
			return trStart + tdSelected + tdPredir + tdStreet + tdHouseStart + tdHouseEnd + tdHouseEOB + tdCity + tdPSAP + tdState + tdPostdir + tdSource + trEnd;
		}
		return '';
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_MSAGAddressSelector(); }
}