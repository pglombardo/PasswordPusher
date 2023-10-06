# pwpush-ephemeral

# Using universal image as a base for old non universal image
# this is for the transition phase since these old image will become obsolete
ARG BASEIMAGE=pwpush:latest
FROM $BASEIMAGE

# Insert decrecation note to inform users while spinning up containers
RUN sed -i '5 a \
            echo "          ##########################################################################          "\n \
            echo "          ###                   !!DEPRECATION NOTIFICATION!!                     ###          "\n \
            echo "          ###  THIS IMAGE IS DEPRECATED. SUPPORT FOR THIS IMAGE WILL BE DROPPED  ###          "\n \
            echo "          ###         IN THE NEAR FUTURE. PLEASE MIGRATE TO THE NEW IMAGE        ###          "\n \
            echo "          ###                                                                    ###          "\n \
            echo "          ###                      FOR MORE INFORMATION GOTO                     ###          "\n \
            echo "          ###            https://github.com/pglombardo/PasswordPusher            ###          "\n \
            echo "          ###                   !!DEPRECATION NOTIFICATION!!                     ###          "\n \
            echo "          ##########################################################################          "\n \
            ' ./containers/docker/pwpush/entrypoint.sh

# Setting database backend
ENV DATABASE_URL=sqlite3:db/db.sqlite3