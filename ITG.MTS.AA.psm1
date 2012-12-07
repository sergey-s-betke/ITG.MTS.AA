New-WebServiceProxy `
	-Uri 'https://aa.mts.ru/api/v1/un.svc?wsdl' `
	-Namespace 'ITG.MTS.AA.UN' `
;
New-WebServiceProxy `
	-Uri 'https://aa.mts.ru/api/v1/cdr.svc?wsdl' `
	-Namespace 'ITG.MTS.AA.CDR' `
;

$Un = New-Object ITG.MTS.AA.UN.un;

function Get-Token {
	<#
		.Component
			API Яндекс
		.Synopsis
			Метод (обёртка над Яндекс.API get_token) предназначен для получения авторизационного токена.
		.Description
			Метод get_token предназначен для получения авторизационного токена.
			Авторизационный токен используется для активации API Яндекс.Почты для доменов. Получать токен
			нужно только один раз. Чтобы получить токен, следует иметь подключенный домен, авторизоваться
			его администратором.
			Синтаксис запроса:
				https://pddimp.yandex.ru/get_token.xml ? domain_name =<имя домена>
			Получение токена для домена yourdomain.ru:
				https://pddimp.yandex.ru/get_token.xml?domain_name=yourdomain.ru
			Формат ответа
			Если ошибок нет, метод возвращает <ok token="..."/>, в противном случае - <error reason='...'/>.
			Но данная функция возвращает непосредственно токен, либо генерирует исключение.
		.Outputs
			[System.String] - собственно token
		.Link
			http://api.yandex.ru/pdd/doc/api-pdd/reference/get-token.xml#get-token
		.Example
			Получение токена для домена yourdomain.ru:
			$token = Get-Token -DomainName 'yourdomain.ru';
	#>

	[CmdletBinding()]
	
	param (
		# имя домена - любой из доменов, зарегистрированных под Вашей учётной записью на сервисах Яндекса
		[Parameter(
			Mandatory=$true,
			Position=0,
			ValueFromPipeline=$true,
			ValueFromRemainingArguments=$true
		)]
		[string]
		[ValidateScript( { $_ -match "^$($reDomain)$" } )]
		[Alias("domain_name")]
		[Alias("Domain")]
		$DomainName
	)

	process {
		$get_tokenURI = [System.Uri]"$APIRoot/get_token.xml?domain_name=$( [System.Uri]::EscapeDataString( $DomainName ) )";
		$get_tokenAuthURI = [System.Uri]"https://passport.yandex.ru/passport?mode=auth&msg=pdd&retpath=$( [System.Uri]::EscapeDataString( $get_tokenURI ) )";

		try {
			Write-Verbose 'Создаём экземпляр InternetExplorer.';
			$ie = New-Object -Comobject InternetExplorer.application;
			Write-Verbose "Отправляем InternetExplorer на Яндекс.Паспорт ($get_tokenAuthURI).";
			$ie.Navigate( $get_tokenAuthURI );
			$ie.Visible = $True;
			
			$ie `
			| Set-WindowZOrder -ZOrder ( [ITG.WinAPI.User32.HWND]::Top ) -PassThru `
			| Set-WindowForeground -PassThru `
			| Out-Null
			;

			Write-Verbose 'Ждём либо пока Яндекс.Паспорт сработает по cookies, либо пока администратор авторизуется на Яндекс.Паспорт...';
			while ( `
				$ie.Busy `
				-or (-not ([System.Uri]$ie.LocationURL).IsBaseOf( $get_tokenURI ) ) `
			) { Sleep -milliseconds 100; };
			$ie.Visible = $False;

			$res = ( [xml]$ie.document.documentElement.innerhtml );
			Write-Debug "Ответ API get_token: $($ie.document.documentElement.innerhtml).";
			if ( $res.ok ) {
				$token = [System.String]$res.ok.token;
				Write-Verbose "Получили токен для домена $($DomainName): $token.";
				return $token;
			} else {
				$errMsg = $res.error.reason;
				Write-Error `
					-Message "Ответ API get_token для домена $DomainName отрицательный." `
					-Category PermissionDenied `
					-CategoryReason $errMsg `
					-CategoryActivity 'Yandex.API.get_token' `
					-CategoryTargetName $DomainName `
					-RecommendedAction 'Проверьте правильность указания домена и Ваши права на домен.' `
				;
			};
		} finally {
			Write-Verbose 'Уничтожаем экземпляр InternetExplorer.';
			$ie.Quit(); 
			$res = [System.Runtime.InteropServices.Marshal]::ReleaseComObject( $ie );
		};
	}
};

Export-ModuleMember `
;