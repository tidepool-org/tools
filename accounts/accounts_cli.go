package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/codegangsta/cli"
	"github.com/howeyc/gopass"
)

type admin struct {
	host   string
	client *http.Client
	User   struct {
		Id    string `json:"userid"`
		Name  string `json:"username"`
		Token string `json:"-"`
	} `json:"administrator"`
	Accounts []*Account `json:"administeredAccounts"`
}

type Account struct {
	Id      string `json:"userid"`
	Profile struct {
		FullName string `json:"fullName"`
		Patient  struct {
			Bday string `json:"birthday"`
			Dday string `json:"diagnosisDate"`
		} `json:"patientDetails"`
	} `json:"patientProfile"`
	Perms      interface{} `json:"permissons"`
	LastUpload string      `json:"lastupload"`
}

var (
	prodHost  = "https://api.tidepool.io"
	localHost = "http://localhost:8009"
)

func main() {

	app := cli.NewApp()

	app.Name = "Accounts-Managment"
	app.Usage = "Allows the bulk management of tidepool accounts"
	app.Version = "0.0.1"
	app.Author = "Jamie Bate"
	app.Email = "jamie@tidepool.com"

	app.Commands = []cli.Command{

		//e.g. audit --af ./accounts.txt
		{
			Name:      "audit",
			ShortName: "a",
			Usage:     `audit all accounts that you have permisson to access`,
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "u, username",
					Usage: "your tidepool username that has access to the accounts e.g. admin@tidepool.org",
				},
				cli.StringFlag{
					Name:  "r, reportpath",
					Usage: "rerun the process on an existing report that you have given the path too e.g -r ./accountsAudit_2015-06-26 08:17:29.445414108 +1200 NZST.txt",
				},
			},
			Action: auditAccounts,
		},
		//e.g. create --af ./new-accounts.txt
		{
			Name:      "invite",
			ShortName: "i",
			Usage:     "create invites to blip for accounts that will be initilized",
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "af, accountsFile",
					Usage: "the text file that has a list of all accounts that you wish to audit",
				},
			},
			Action: createInvites,
		},
	}

	app.Run(os.Args)

}

func (a *admin) findPublicInfo(acc *Account) error {

	urlPath := a.host + fmt.Sprintf("/metadata/%s/profile", acc.Id)

	req, _ := http.NewRequest("GET", urlPath, nil)
	req.Header.Add("x-tidepool-session-token", a.User.Token)

	res, err := a.client.Do(req)

	if err != nil {
		return errors.New("Could attempt to find profile: " + err.Error())
	}

	switch res.StatusCode {
	case 200:
		data, _ := ioutil.ReadAll(res.Body)
		json.Unmarshal(data, &acc.Profile)
		return nil
	default:
		log.Printf("Failed finding public info [%d] for [%s]", res.StatusCode, acc.Id)
		return nil
	}
}

func (a *admin) findLastUploaded(acc *Account) error {

	urlPath := a.host + fmt.Sprintf("/query/upload/lastentry/%s", acc.Id)

	req, _ := http.NewRequest("GET", urlPath, nil)
	req.Header.Add("x-tidepool-session-token", a.User.Token)

	res, err := a.client.Do(req)

	if err != nil {
		return errors.New("Could attempt to find the last upload: " + err.Error())
	}

	switch res.StatusCode {
	case 200:
		data, _ := ioutil.ReadAll(res.Body)
		json.Unmarshal(data, &acc.LastUpload)
		return nil
	default:
		log.Printf("Failed finding last upload info [%d] for [%s]", res.StatusCode, acc.Profile.FullName)
		return nil
	}
}

func (a *admin) login(un, pw string) error {

	urlPath := a.host + "/auth/login"

	req, _ := http.NewRequest("POST", urlPath, nil)
	req.SetBasicAuth(un, pw)

	res, err := a.client.Do(req)
	if err != nil {
		return errors.New(fmt.Sprint("Login request failed", err.Error()))
	}

	switch res.StatusCode {
	case 200:
		data, _ := ioutil.ReadAll(res.Body)
		json.Unmarshal(data, &a.User)
		a.User.Token = res.Header.Get("x-tidepool-session-token")
		return nil
	default:
		return errors.New(fmt.Sprint("Login failed", res.StatusCode))
	}
}

func (a *admin) findAccounts() error {

	urlPath := a.host + fmt.Sprintf("/access/groups/%s", a.User.Id)

	req, _ := http.NewRequest("GET", urlPath, nil)
	req.Header.Add("x-tidepool-session-token", a.User.Token)

	res, err := a.client.Do(req)

	if err != nil {
		return errors.New("Could attempt to find administered accounts: " + err.Error())
	}

	switch res.StatusCode {
	case 200:
		data, _ := ioutil.ReadAll(res.Body)

		var raw map[string]interface{}

		json.Unmarshal(data, &raw)

		for key, value := range raw {
			a.Accounts = append(a.Accounts, &Account{Id: string(key), Perms: value})
		}
		return nil
	default:
		log.Println("Failed finding profiles", res.StatusCode)
		return nil
	}
}

func (a *admin) loadExistingReport(path string) error {
	log.Println("loading audit report ...")

	rf, err := os.Open(path)
	if err != nil {
		return err
	}

	jsonParser := json.NewDecoder(rf)
	if err = jsonParser.Decode(&a); err != nil {
		return err
	}
	rf.Close()
	return nil
}

// and audit will find all account linked
func auditAccounts(c *cli.Context) {

	adminUser := &admin{host: localHost, client: &http.Client{}}

	if c.String("username") == "" {
		log.Fatal("Please specify the username with the --username or -u flag.")
	}

	fmt.Printf("Password: ")
	pass := gopass.GetPasswdMasked()

	err := adminUser.login(c.String("username"), string(pass[:]))
	if err != nil {
		log.Println(err.Error())
		return
	}

	if c.String("reportpath") == "" {

		//get accounts I can view
		log.Println("finding administered accounts ...")
		err = adminUser.findAccounts()
		if err != nil {
			log.Println(err.Error())
			return
		}

		//find the accociated profiles
		log.Println("running audit on accounts ...")
		for i := range adminUser.Accounts {
			err = adminUser.findPublicInfo(adminUser.Accounts[i])
			if err != nil {
				log.Println(err.Error())
				return
			}
			err = adminUser.findLastUploaded(adminUser.Accounts[i])
			if err != nil {
				log.Println(err.Error())
				return
			}
		}
	} else {
		//find the accociated profiles
		log.Println("re-running audit on accounts ...")

		err = adminUser.loadExistingReport(c.String("reportpath"))
		if err != nil {
			log.Println(err.Error())
			return
		}
		for i := range adminUser.Accounts {
			err = adminUser.findLastUploaded(adminUser.Accounts[i])
			if err != nil {
				log.Println(err.Error())
				return
			}
		}
	}
	log.Println("building audit report ...")
	jsonRpt, _ := json.MarshalIndent(&adminUser, "", "  ")

	reportPath := fmt.Sprintf("./accountsAudit_%s.txt", time.Now().String())

	f, _ := os.Create(reportPath)
	defer f.Close()
	f.Write(jsonRpt)
	log.Println("done! here is the report " + reportPath)
	//see when they last uploaded

	return
}

func createInvites(c *cli.Context) {

	if c.String("accountsFile") == "" {
		log.Fatal("Please specify file (and path to it) that contains the list of accounts you wish to audit --accountsFile or -af flag.")
	}

}
