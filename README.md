# Nobus Cloud hackathon starter

One command takes a fresh Nobus server to a live URL for your project.

## Before you start (in the Nobus dashboard, dashboard.nobus.io)

1. **Security group:** inbound TCP 22 from My IP, TCP 80 and TCP 443 from Anywhere.
2. **Server:** Project › Compute › Instances › Launch Instance. Image `Ubuntu-22.04-64bit`, a small flavour, your security group, a new key pair (download the `.pem` file; it downloads once).
3. **Floating IP:** associate one with your server.
4. **Log in:** `ssh -i yourkey.pem ubuntu@YOUR-FLOATING-IP` (on Mac or Linux, run `chmod 400 yourkey.pem` first).

## Deploy

On the server:

```bash
git clone https://github.com/UNCTekHub/nobus-hackathon-starter.git nobus-starter
cd nobus-starter && chmod +x deploy.sh
./deploy.sh https://github.com/your-team/your-repo.git 3000
```

With your domain and HTTPS (add an A record for your domain pointing at your floating IP first):

```bash
./deploy.sh https://github.com/your-team/your-repo.git 3000 yourteam.com.ng you@example.com
```

After every `git push`, run the same command again to redeploy.

A private repository needs access first: use an HTTPS URL with a personal access token, or add the server's SSH key as a deploy key.

## What your repository needs

- A `Dockerfile`, or a `docker-compose.yml`. If you have neither, copy the ones in `sample-app/` and adjust them.
- An app that listens on `0.0.0.0` and the port you pass to `deploy.sh` (default 3000). Not `localhost`.
- With docker-compose, publish that port to the host as `127.0.0.1:3000:3000`, as `sample-app/docker-compose.yml` does.
- Secrets in `.env` on the server, never in Git. The script creates `.env` from `.env.example` if you have one.

## What the script does

1. Installs Git, Nginx and Docker (first run only).
2. Clones your repository to `~/app`, or pulls the latest code.
3. Builds and starts your app with Docker, set to restart by itself.
4. Points Nginx at your app.
5. If you give a domain, gets a free Let's Encrypt certificate and turns on HTTPS.

## If something goes wrong

| What you see | Fix |
| --- | --- |
| SSH just hangs | Set the port 22 rule to My IP again (it changes on mobile data) |
| Permission denied (publickey) | User is `ubuntu`; use the right `.pem` file |
| 502 Bad Gateway | Your app isn't running: `cd ~/app && sudo docker compose logs` (or `sudo docker logs hackathon-app`) |
| Site won't load on the IP | Open ports 80 and 443 in your security group |
| HTTPS step fails | Check the A record, wait a few minutes, run the script again |

Need help? Find the Nobus team at [TABLE OR LOCATION] or [WHATSAPP OR PHONE].
