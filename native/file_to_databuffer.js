function loadFile(file, buf)
{
	var reader = new FileReader();

	reader.onloadend = function ()
	{
		var rawData = reader.result;

		if (rawData == null)
		{
			return;
		}
		
		buf._Init(rawData);
	}

	reader.readAsArrayBuffer(file);
}